import 'dart:async';
import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/modules/Home/Widgets/outlet_bottomsheet.dart';
import 'package:billkaro/app/services/outlet_scope_refresh.dart';
import 'package:billkaro/app/modules/Home/payment_controller.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:billkaro/utils/staff_outlet_sync.dart';

// Chart period filter enum (must be top-level)
enum ChartPeriod { weekly, monthly, quarterly, yearly }

class HomeScreenController extends BaseController {
  var todaySales = 0.00.obs;
  var yesterdaySales = 0.00.obs;
  var todayOrders = 0.obs;
  var yesterdayOrders = 0.obs;
  var selectedIndex = 0.obs;
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;
  final RxList<OrderModel> occupiedTableOrders = <OrderModel>[].obs;
  final RxList<OrderModel> ordersL = <OrderModel>[].obs;
  final printerservice2 = PrinterService2.to;
  final Map<String, String> _itemImageById = <String, String>{};
  final Map<String, String> _itemImageByName = <String, String>{};

  // Chart period filter
  final Rx<ChartPeriod> selectedChartPeriod = ChartPeriod.weekly.obs;

  // Sales data for chart (dynamic based on period)
  final RxList<double> chartSalesData = <double>[0, 0, 0, 0, 0, 0, 0].obs;

  // Chart labels (X-axis) based on period
  final RxList<String> chartLabels = <String>[].obs;

  /// Category-wise sales for today (based on order items: quantity * salePrice)
  final RxList<CategorySales> todayCategorySales = <CategorySales>[].obs;
  final RxList<TopSellingItem> topSellingItems = <TopSellingItem>[].obs;

  // Add this observable for selected outlet
  final Rx<OutletData?> selectedOutlet = Rx<OutletData?>(null);

  // Loading state
  final RxBool isLoadingOrders = false.obs;

  // KOT mode (reactive so UI updates immediately)
  final RxBool isKOT = false.obs;

  // Connectivity listener
  StreamSubscription<bool>? _connectivitySubscription;
  bool _lastConnectivityState = false;
  bool _hasLoadedFromApi = false;

  @override
  void onReady() async {
    await getUserDetails();

    // sync KOT mode from preferences
    isKOT.value = appPref.isKOT;

    // Initialize selected outlet from appPref
    selectedOutlet.value = appPref.selectedOutlet;

    // Auto-select first outlet if none selected
    if (!appPref.hasSelectedOutlet && appPref.allOutlets.isNotEmpty) {
      // appPref.selectFirstOutlet();
      selectedOutlet.value = appPref.selectedOutlet;
      debugPrint(
        '🏪 Auto-selected first outlet: ${appPref.selectedOutlet?.businessName}',
      );
    }

    // Initial load
    await getOrderList();

    // Listen to connectivity changes - only call API when coming back online
    _connectivitySubscription = ConnectivityHelper.instance.onConnectivityChange
        .listen((isConnected) {
          // Only trigger API call when transitioning from offline to online
          if (isConnected && !_lastConnectivityState && !_hasLoadedFromApi) {
            debugPrint('🌐 Internet came back - refreshing orders from API');
            getOrderList(forceApiRefresh: true);
          }
          _lastConnectivityState = isConnected;
        });

    // Initialize last connectivity state
    _lastConnectivityState = ConnectivityHelper.instance.isConnected;

    super.onReady();
  }

  void setKotMode(bool value) {
    appPref.isKOT = value;
    isKOT.value = value;

    // Push into other live controllers so they update immediately.
    if (Get.isRegistered<AddOrderController>()) {
      Get.find<AddOrderController>().isKOT.value = value;
    }
    if (Get.isRegistered<OrderPreferencesController>()) {
      Get.find<OrderPreferencesController>().kotModeEnabled.value = value;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> getUserDetails() async {
    final user = appPref.user;
    if (user == null) return;

    final bool isStaff = user.role == 'staff';
    final String? profileId = isStaff ? user.id : appPref.ownerUserId;
    if (profileId == null || profileId.isEmpty) return;

    final response = await callApi(
      isStaff
          ? apiClient.getStaffProfile(profileId)
          : apiClient.getUserDetails(profileId),
      showLoader: false,
    );

    if (response?.status != 'success' || response?.data == null) return;

    if (isStaff) {
      await StaffOutletSync.enrichAppPrefFromOwner(
        appPref: appPref,
        staffUser: response!.data,
        apiClient: apiClient,
      );
    } else {
      appPref.user = response!.data;
    }

      // 🔁 Re-sync selected outlet from updated outlet list
      final currentSelectedId = appPref.selectedOutlet?.id;

      if (currentSelectedId != null) {
        final updatedOutlet = appPref.allOutlets.firstWhereOrNull(
          (o) => o.id == currentSelectedId,
        );

        if (updatedOutlet != null) {
          appPref.selectedOutlet = updatedOutlet;
          selectedOutlet.value = updatedOutlet;
        } else if (appPref.allOutlets.isNotEmpty) {
          // fallback if outlet was removed
          appPref.selectFirstOutlet();
          selectedOutlet.value = appPref.selectedOutlet;
        }
      } else if (appPref.allOutlets.isNotEmpty) {
        // No outlet selected yet
        appPref.selectFirstOutlet();
        selectedOutlet.value = appPref.selectedOutlet;
      }

      update(); // refresh UI
  }

  Future<void> getOrderList({bool forceApiRefresh = false}) async {
    try {
      isLoadingOrders.value = true;

      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return;

      final isOnline = await NetworkUtils.hasInternetConnection();
      final db = AppDatabase();

      debugPrint('🔄 isOnline: $isOnline');

      /// ===============================
      /// 📦 STEP 1 → ALWAYS LOAD SQLITE
      /// ===============================
      final localOrders = await db.getAllOrders(outletId: outletId);
      occupiedTableOrders.value = _buildOccupiedTableOrders(localOrders);

      allOrders.value = localOrders.where((e) => e.status == 'closed').toList();

      debugPrint('📦 Loaded ${allOrders.length} orders from SQLite');

      /// ===============================
      /// 🔌 STEP 2 → IF ONLINE, SYNC API (only if not already loaded or forced)
      /// ===============================
      if (isOnline && (!_hasLoadedFromApi || forceApiRefresh)) {
        debugPrint('🌐 Internet available → fetching from API');

        final response = await callApi(
          apiClient.getOrders(
            appPref.ordersApiUserId!,
            outletId,
            null,
            null,
            null,
            null,
            null,
            null,
          ),
          showLoader: false,
        );

        if (response?.status == 'success') {
          final apiOrders = response!.data;

          /// Save to SQLite
          await db.insertOrders(apiOrders, outletId, isSyncedFromApi: true);

          /// Reload from SQLite (single source of truth)
          final updatedOrders = await db.getAllOrders(outletId: outletId);
          occupiedTableOrders.value = _buildOccupiedTableOrders(updatedOrders);

          allOrders.value = updatedOrders
              .where((e) => e.status == 'closed')
              .toList();

          _hasLoadedFromApi = true;
          debugPrint('✅ Orders synced & refreshed (${allOrders.length})');

          // Refresh payment statistics
          if (Get.isRegistered<PaymentController>()) {
            Get.find<PaymentController>().refresh();
          }
        }
      } else if (!isOnline) {
        // If offline, reset the flag so we'll try again when online
        _hasLoadedFromApi = false;
      }

      /// ===============================
      /// 📊 COMMON CALCULATIONS
      /// ===============================
      await _loadItemImageMap(outletId);
      _calculateSalesData();
      await _enrichTopSellingImages(outletId);
      _calculateChartSalesData();

      // Refresh payment statistics after calculations
      if (Get.isRegistered<PaymentController>()) {
        Get.find<PaymentController>().refresh();
      }
    } catch (e) {
      debugPrint('❌ Order load error on homescreen: $e');
      showError(
        description: AppLocalizations.of(Get.context!)!.failed_to_load_orders,
      );
    } finally {
      isLoadingOrders.value = false;
    }
  }

  void _calculateSalesData() {
    final today = todayIstDateOnly();
    final yesterday = today.subtract(const Duration(days: 1));

    double todaySalesTotal = 0.0;
    double yesterdaySalesTotal = 0.0;
    int todayOrdersCount = 0;
    int yesterdayOrdersCount = 0;

    final Map<String, CategorySales> todayByCategory = {};
    final Map<String, TopSellingItem> allTimeByItem = {};

    for (var order in allOrders) {
      late final DateTime orderDateOnly;
      try {
        orderDateOnly = orderCreatedAtToIstDateOnly(order.createdAt.toString());
      } catch (e) {
        debugPrint('Error parsing date for order: $e');
        continue;
      }
      final orderTotal = order.totalAmount;

      for (final item in order.items) {
        final itemName = item.itemName.trim().isEmpty
            ? 'Unnamed Item'
            : item.itemName.trim();
        final amount = item.salePrice * item.quantity;
        final itemId = item.itemId.trim();
        final itemKey = itemId.isEmpty ? itemName : itemId;
        final imageUrl = _imageForItem(itemId: itemId, itemName: itemName);
        final category = item.category.trim().isEmpty
            ? 'Uncategorized'
            : item.category.trim();
        final existingItem = allTimeByItem[itemKey];
        if (existingItem == null) {
          allTimeByItem[itemKey] = TopSellingItem(
            itemId: itemId,
            name: itemName,
            category: category,
            imageUrl: imageUrl,
            quantity: item.quantity,
            amount: amount,
          );
        } else {
          allTimeByItem[itemKey] = TopSellingItem(
            itemId: existingItem.itemId,
            name: existingItem.name,
            category: existingItem.category.isEmpty
                ? category
                : existingItem.category,
            imageUrl: existingItem.imageUrl.isEmpty
                ? imageUrl
                : existingItem.imageUrl,
            quantity: existingItem.quantity + item.quantity,
            amount: existingItem.amount + amount,
          );
        }
      }

      if (orderDateOnly == today) {
        todaySalesTotal += orderTotal;
        todayOrdersCount++;

        // Category-wise aggregation for today
        for (final item in order.items) {
          final category = item.category.trim().isEmpty
              ? 'none'
              : item.category.trim();
          final amount = item.salePrice * item.quantity;
          final existing = todayByCategory[category];
          if (existing == null) {
            todayByCategory[category] = CategorySales(
              category: category,
              amount: amount,
              quantity: item.quantity,
            );
          } else {
            todayByCategory[category] = CategorySales(
              category: category,
              amount: existing.amount + amount,
              quantity: existing.quantity + item.quantity,
            );
          }
        }
      } else if (orderDateOnly == yesterday) {
        yesterdaySalesTotal += orderTotal;
        yesterdayOrdersCount++;
      }
    }

    todaySales.value = todaySalesTotal;
    yesterdaySales.value = yesterdaySalesTotal;
    todayOrders.value = todayOrdersCount;
    yesterdayOrders.value = yesterdayOrdersCount;

    // Publish today category-wise data sorted by amount desc
    final sorted = todayByCategory.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    todayCategorySales.value = sorted;

    final sortedItems = allTimeByItem.values.toList()
      ..sort((a, b) {
        final quantityCompare = b.quantity.compareTo(a.quantity);
        if (quantityCompare != 0) return quantityCompare;
        return b.amount.compareTo(a.amount);
      });
    topSellingItems.value =
        StaffAccess.canViewProducts ? sortedItems : <TopSellingItem>[];

    debugPrint('📊 Today: ₹$todaySalesTotal ($todayOrdersCount orders)');
    debugPrint(
      '📊 Yesterday: ₹$yesterdaySalesTotal ($yesterdayOrdersCount orders)',
    );
  }

  String _normalizeTableNumber(String raw) {
    var value = raw.trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^table\s*'), '');
    value = value.replaceAll(RegExp(r'\s+'), '');
    return value;
  }

  DateTime _parseSafeDate(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<OrderModel> _buildOccupiedTableOrders(List<OrderModel> orders) {
    final Map<String, OrderModel> latestOrderByTable = {};

    for (final order in orders) {
      final status = order.status.trim().toLowerCase();
      if (status == 'closed') continue;

      final orderFrom = order.orderFrom.trim().toLowerCase();
      if (orderFrom != 'dine in') continue;

      final rawTable = (order.tableNumber ?? '').trim();
      final tableKey = _normalizeTableNumber(rawTable);
      if (tableKey.isEmpty) continue;

      final existing = latestOrderByTable[tableKey];
      if (existing == null) {
        latestOrderByTable[tableKey] = order;
        continue;
      }

      if (_parseSafeDate(
        order.updatedAt,
      ).isAfter(_parseSafeDate(existing.updatedAt))) {
        latestOrderByTable[tableKey] = order;
      }
    }

    final rows = latestOrderByTable.values.toList()
      ..sort(
        (a, b) =>
            _parseSafeDate(b.updatedAt).compareTo(_parseSafeDate(a.updatedAt)),
      );
    return rows;
  }

  void _calculateChartSalesData() {
    switch (selectedChartPeriod.value) {
      case ChartPeriod.weekly:
        _calculateWeeklySalesData();
        break;
      case ChartPeriod.monthly:
        _calculateMonthlySalesData();
        break;
      case ChartPeriod.quarterly:
        _calculateQuarterlySalesData();
        break;
      case ChartPeriod.yearly:
        _calculateYearlySalesData();
        break;
    }
  }

  void _calculateWeeklySalesData() {
    final today = todayIstDateOnly();

    // Initialize weekly sales array (last 7 days)
    List<double> weeklySales = List.filled(7, 0.0);
    List<String> labels = [];

    // Generate day labels (Mon, Tue, Wed, etc.)
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      labels.add(days[date.weekday - 1]);
    }

    // Calculate sales for each of the last 7 days
    for (var order in allOrders) {
      late final DateTime orderDateOnly;
      try {
        orderDateOnly = orderCreatedAtToIstDateOnly(order.createdAt.toString());
      } catch (e) {
        continue;
      }
      final daysDifference = today.difference(orderDateOnly).inDays;

      if (daysDifference >= 0 && daysDifference < 7) {
        final orderTotal = order.totalAmount;
        weeklySales[6 - daysDifference] += orderTotal;
      }
    }

    chartSalesData.value = List<double>.from(weeklySales);
    chartLabels.value = labels;
  }

  void _calculateMonthlySalesData() {
    final ist = todayIstDateOnly();

    // Last 12 months
    List<double> monthlySales = List.filled(12, 0.0);
    List<String> labels = [];

    // Generate month labels
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(ist.year, ist.month - i, 1);
      if (date.month <= 0) {
        labels.add(monthNames[date.month + 12 - 1]);
      } else {
        labels.add(monthNames[date.month - 1]);
      }
    }

    for (var order in allOrders) {
      late final DateTime orderIst;
      try {
        orderIst = orderCreatedAtToIstDateOnly(order.createdAt.toString());
      } catch (e) {
        continue;
      }

      final monthsAgo =
          (ist.year - orderIst.year) * 12 + (ist.month - orderIst.month);

      if (monthsAgo >= 0 && monthsAgo < 12) {
        monthlySales[11 - monthsAgo] += order.totalAmount;
      }
    }

    chartSalesData.value = List<double>.from(monthlySales);
    chartLabels.value = labels;
  }

  void _calculateQuarterlySalesData() {
    final ist = todayIstDateOnly();

    // Last 4 quarters
    List<double> quarterlySales = List.filled(4, 0.0);
    List<String> labels = [];

    // Generate quarter labels
    for (int i = 3; i >= 0; i--) {
      final quarterDate = DateTime(ist.year, ist.month - (i * 3), 1);
      final quarter = ((quarterDate.month - 1) ~/ 3) + 1;
      labels.add('Q$quarter ${quarterDate.year.toString().substring(2)}');
    }

    for (var order in allOrders) {
      late final DateTime orderIst;
      try {
        orderIst = orderCreatedAtToIstDateOnly(order.createdAt.toString());
      } catch (e) {
        continue;
      }

      final orderQuarter = ((orderIst.month - 1) ~/ 3) + 1;
      final orderYear = orderIst.year;
      final currentQuarter = ((ist.month - 1) ~/ 3) + 1;
      final currentYear = ist.year;

      int quartersAgo =
          (currentYear - orderYear) * 4 + (currentQuarter - orderQuarter);

      if (quartersAgo >= 0 && quartersAgo < 4) {
        quarterlySales[3 - quartersAgo] += order.totalAmount;
      }
    }

    chartSalesData.value = List<double>.from(quarterlySales);
    chartLabels.value = labels;
  }

  void _calculateYearlySalesData() {
    final ist = todayIstDateOnly();

    // Last 5 years
    List<double> yearlySales = List.filled(5, 0.0);
    List<String> labels = [];

    // Generate year labels
    for (int i = 4; i >= 0; i--) {
      final year = ist.year - i;
      labels.add(year.toString());
    }

    for (var order in allOrders) {
      late final DateTime orderIst;
      try {
        orderIst = orderCreatedAtToIstDateOnly(order.createdAt.toString());
      } catch (e) {
        continue;
      }

      final yearsAgo = ist.year - orderIst.year;

      if (yearsAgo >= 0 && yearsAgo < 5) {
        yearlySales[4 - yearsAgo] += order.totalAmount;
      }
    }

    chartSalesData.value = List<double>.from(yearlySales);
    chartLabels.value = labels;
  }

  void setChartPeriod(ChartPeriod period) {
    selectedChartPeriod.value = period;
    _calculateChartSalesData();
  }

  void _ingestItemImages(Iterable<ItemData> items) {
    for (final item in items) {
      final image = resolvedMediaUrl(item.itemImage);
      if (image.isEmpty) continue;

      final id = item.id.trim();
      if (id.isNotEmpty) {
        _itemImageById[id] = image;
      }
      final name = item.itemName.trim().toLowerCase();
      if (name.isNotEmpty) {
        _itemImageByName[name] = image;
      }
    }
  }

  String _imageForItem({required String itemId, required String itemName}) {
    final byId = itemId.trim().isEmpty
        ? ''
        : (_itemImageById[itemId.trim()] ?? '');
    if (byId.isNotEmpty) return byId;
    final name = itemName.trim().toLowerCase();
    if (name.isEmpty) return '';
    return _itemImageByName[name] ?? '';
  }

  Future<void> _loadItemImageMap(String outletId) async {
    try {
      _itemImageById.clear();
      _itemImageByName.clear();

      final db = AppDatabase();

      // 1) Local SQLite (may only contain a paginated subset from Items screen)
      _ingestItemImages(
        (await db.getItemsPage(outletId: outletId, limit: 300)).items,
      );

      // 2) In-memory catalogs already loaded elsewhere in the app
      if (Get.isRegistered<MenuItemController>()) {
        _ingestItemImages(Get.find<MenuItemController>().allItems);
      }
      if (Get.isRegistered<AddOrderController>()) {
        _ingestItemImages(Get.find<AddOrderController>().allItemsMap.values);
      }

      // 3) Always refresh a full catalog page when online so top-sellers
      //    that were never opened in Items still get their image URLs.
      final isOnline = await NetworkUtils.hasInternetConnection();
      if (isOnline) {
        final response = await callApi(
          apiClient.getItems(outletId, 1, 500, null, null, null, null),
          showLoader: false,
        );
        if (response?.status == 'success' && response!.data.isNotEmpty) {
          _ingestItemImages(response.data);
          await db.saveItems(response.data, outletId);
        }
      }

      debugPrint(
        '🖼️ Top-selling image map: '
        '${_itemImageById.length} by id, ${_itemImageByName.length} by name',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to load item image map: $e');
    }
  }

  /// Fills any remaining missing thumbnails via best-selling API (includes itemImage).
  Future<void> _enrichTopSellingImages(String outletId) async {
    if (!StaffAccess.canViewProducts) return;
    try {
      final missing = topSellingItems
          .take(5)
          .where((item) => item.imageUrl.trim().isEmpty)
          .toList();
      if (missing.isEmpty) return;

      final userId = appPref.ordersApiUserId;
      if (userId == null) return;

      final isOnline = await NetworkUtils.hasInternetConnection();
      if (!isOnline) return;

      final response = await callApi(
        apiClient.getBestSellingItems(userId, outletId, 10),
        showLoader: false,
      );
      if (response is! Map || response['status'] != 'success') return;

      final rows = (response['data'] as List?) ?? const [];
      for (final row in rows) {
        if (row is! Map) continue;
        final itemJson = row['item'];
        final itemId = (row['itemId'] ??
                (itemJson is Map ? itemJson['id'] : null))
            ?.toString()
            .trim() ??
            '';
        final itemName = (row['itemName'] ??
                (itemJson is Map ? itemJson['itemName'] : null))
            ?.toString()
            .trim() ??
            '';
        final rawImage = itemJson is Map
            ? (itemJson['itemImage']?.toString() ?? '')
            : '';
        final image = resolvedMediaUrl(rawImage);
        if (image.isEmpty) continue;
        if (itemId.isNotEmpty) {
          _itemImageById[itemId] = image;
        }
        if (itemName.isNotEmpty) {
          _itemImageByName[itemName.toLowerCase()] = image;
        }
      }

      // Re-apply images onto the already-computed top sellers.
      topSellingItems.value = topSellingItems.map((item) {
        if (item.imageUrl.trim().isNotEmpty) return item;
        final imageUrl = _imageForItem(
          itemId: item.itemId,
          itemName: item.name,
        );
        if (imageUrl.isEmpty) return item;
        return TopSellingItem(
          itemId: item.itemId,
          name: item.name,
          category: item.category,
          imageUrl: imageUrl,
          quantity: item.quantity,
          amount: item.amount,
        );
      }).toList();

      debugPrint(
        '🖼️ Enriched top-selling images; '
        'with image: ${topSellingItems.take(5).where((e) => e.imageUrl.isNotEmpty).length}/'
        '${topSellingItems.take(5).length}',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to enrich top-selling images: $e');
    }
  }

  /// Select an outlet
  void selectOutlet(OutletData outlet, {bool closeSheet = true}) {
    final previousOutlet = appPref.selectedOutlet;

    appPref.selectedOutlet = outlet;
    selectedOutlet.value = outlet; // Update observable
    debugPrint('🏪 Outlet selected: ${outlet.businessName}');

    // Only reload data if outlet actually changed
    if (previousOutlet?.id != outlet.id) {
      onOutletChanged();
    }
    if (closeSheet) {
      Get.back();
    }
  }

  /// Delete an outlet from the manage-outlets dialog (owner only).
  Future<void> deleteOutlet(OutletData outlet) async {
    if (!StaffAccess.isOwnerSession) return;

    final deletedOutletId = outlet.id;
    if (deletedOutletId == null || deletedOutletId.isEmpty) return;

    final loc = AppLocalizations.of(Get.context!);
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(loc?.delete_outlet ?? 'Delete Outlet'),
            ),
          ],
        ),
        content: Text(
          'Delete ${outlet.businessName ?? 'this outlet'}?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: Text(loc?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ownerId = appPref.ownerUserId;
      if (ownerId == null) return;

      final wasSelected = selectedOutlet.value?.id == deletedOutletId;
      final res = await callApi(
        apiClient.deleteOutlet(ownerId, deletedOutletId),
      );

      if (res['status'] != 'success') {
        showError(
          description:
              res['message']?.toString() ??
              (loc?.failed_to_delete_outlet ?? 'Failed to delete outlet'),
        );
        return;
      }

      try {
        final db = Get.isRegistered<AppDatabase>()
            ? Get.find<AppDatabase>()
            : AppDatabase();
        await db.clearOutletData(deletedOutletId);
      } catch (e) {
        debugPrint('⚠️ clearOutletData failed: $e');
      }

      await getUserDetails();

      try {
        while (Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (_) {}

      if (appPref.allOutlets.isEmpty) {
        appPref.selectedOutlet = null;
        selectedOutlet.value = null;
        Get.offAllNamed(AppRoute.createOutlet);
        return;
      }

      if (wasSelected) {
        selectedOutlet.value = appPref.selectedOutlet;
        onOutletChanged();
      } else {
        selectedOutlet.refresh();
      }
    } catch (e) {
      debugPrint('❌ deleteOutlet error: $e');
      showError(
        description: loc?.failed_to_delete_outlet ?? 'Failed to delete outlet',
      );
    }
  }

  /// Called when outlet changes - reload all outlet-specific data
  void onOutletChanged() {
    // Stay on current route; restarting home route here re-creates ModularApp
    // and can trigger "Module ... is already started" exceptions.
    // Instead we clear dashboard state, drop outlet-scoped GetX controllers,
    // and re-fetch shell data for the newly selected outlet.
    allOrders.value = <OrderModel>[];
    todaySales.value = 0.0;
    yesterdaySales.value = 0.0;
    todayOrders.value = 0;
    yesterdayOrders.value = 0;
    chartSalesData.value = List<double>.generate(7, (_) => 0.0);
    todayCategorySales.value = <CategorySales>[];
    topSellingItems.value = <TopSellingItem>[];
    occupiedTableOrders.value = <OrderModel>[];
    _hasLoadedFromApi = false;
    update();

    unawaited(() async {
      await refreshOutletScopedControllers();
      await getOrderList(forceApiRefresh: true);
      update();
    }());
  }

  /// Refresh outlets from server
  Future<void> refreshOutlets() async {
    try {
      // showLoading();

      // Fetch updated user data with outlets
      getUserDetails();

      // hideLoading();

      update(); // Refresh UI
    } catch (e) {
      // hideLoading();
      showError(
        description: AppLocalizations.of(
          Get.context!,
        )!.failed_to_refresh_outlets,
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    // Show confirmation dialog
    final loc = AppLocalizations.of(Get.context!)!;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(loc.logout),
        content: Text(loc.logout_confirmation),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc.cancel, style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(loc.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // showLoading();

      // Clear all local data
      final db = AppDatabase();
      await db.clearAllData(); // Clear all database data
      await appPref.clearAllData(); // Clear all SharedPreferences data
      await ThemeController.resetAfterLogout();

      // hideLoading();

      Get.offAllNamed(AppRoute.login); // Navigate to login screen

      showSuccess(
        title: loc.home_logged_out,
        description: loc.home_logged_out_message,
      );
    }
  }

  void showOutletBottomSheet(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (context) => const OutletBottomSheet(),
    );
  }

  /// Get current selected outlet name for display
  String get selectedOutletName =>
      selectedOutlet.value?.businessName ?? 'Select Outlet';

  /// Check if outlet is selected
  bool get hasSelectedOutlet => selectedOutlet.value != null;
}

class CategorySales {
  final String category;
  final double amount;
  final int quantity;

  const CategorySales({
    required this.category,
    required this.amount,
    required this.quantity,
  });
}

class TopSellingItem {
  final String itemId;
  final String name;
  final String category;
  final String imageUrl;
  final int quantity;
  final double amount;

  const TopSellingItem({
    required this.itemId,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.quantity,
    required this.amount,
  });
}
