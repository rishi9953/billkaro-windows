import 'dart:async';
import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/modules/Home/Widgets/outlet_bottomsheet.dart';
import 'package:billkaro/app/modules/Home/payment_controller.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_controller.dart';
import 'package:billkaro/config/config.dart';

// Chart period filter enum (must be top-level)
enum ChartPeriod { weekly, monthly, quarterly, yearly }

class HomeScreenController extends BaseController {
  var todaySales = 0.00.obs;
  var yesterdaySales = 0.00.obs;
  var todayOrders = 0.obs;
  var yesterdayOrders = 0.obs;
  var selectedIndex = 0.obs;
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;
  final RxList<OrderModel> ordersL = <OrderModel>[].obs;
  final printerservice2 = PrinterService2.to;

  // Chart period filter
  final Rx<ChartPeriod> selectedChartPeriod = ChartPeriod.weekly.obs;

  // Sales data for chart (dynamic based on period)
  final RxList<double> chartSalesData = <double>[0, 0, 0, 0, 0, 0, 0].obs;

  // Chart labels (X-axis) based on period
  final RxList<String> chartLabels = <String>[].obs;

  /// Category-wise sales for today (based on order items: quantity * salePrice)
  final RxList<CategorySales> todayCategorySales = <CategorySales>[].obs;

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
    final response = await callApi(
      apiClient.getUserDetails(appPref.user!.id!),
      showLoader: false,
    );

    if (response?.status == 'success') {
      appPref.user = response!.data;

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

      allOrders.value = localOrders.where((e) => e.status == 'closed').toList();

      debugPrint('📦 Loaded ${allOrders.length} orders from SQLite');

      /// ===============================
      /// 🔌 STEP 2 → IF ONLINE, SYNC API (only if not already loaded or forced)
      /// ===============================
      if (isOnline && (!_hasLoadedFromApi || forceApiRefresh)) {
        debugPrint('🌐 Internet available → fetching from API');

        final response = await callApi(
          apiClient.getOrders(appPref.user!.id!, outletId, null, null, null, null, null, null),
          showLoader: false,
        );

        if (response?.status == 'success') {
          final apiOrders = response!.data
              .where((e) => e.status == 'closed')
              .toList();

          /// Save to SQLite
          await db.insertOrders(apiOrders, outletId, isSyncedFromApi: true);

          /// Reload from SQLite (single source of truth)
          final updatedOrders = await db.getAllOrders(outletId: outletId);

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
      _calculateSalesData();
      _calculateChartSalesData();

      // Refresh payment statistics after calculations
      if (Get.isRegistered<PaymentController>()) {
        Get.find<PaymentController>().refresh();
      }
    } catch (e) {
      debugPrint('❌ Order load error on homescreen: $e');
      showError(description: 'Failed to load orders');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  void _calculateSalesData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    double todaySalesTotal = 0.0;
    double yesterdaySalesTotal = 0.0;
    int todayOrdersCount = 0;
    int yesterdayOrdersCount = 0;

    final Map<String, CategorySales> todayByCategory = {};

    for (var order in allOrders) {
      DateTime? orderDate;

      try {
        orderDate = DateTime.parse(order.createdAt.toString());
      } catch (e) {
        debugPrint('Error parsing date for order: $e');
        continue;
      }

      final orderDateOnly = DateTime(
        orderDate.year,
        orderDate.month,
        orderDate.day,
      );
      final orderTotal = order.totalAmount;

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

    debugPrint('📊 Today: ₹$todaySalesTotal ($todayOrdersCount orders)');
    debugPrint(
      '📊 Yesterday: ₹$yesterdaySalesTotal ($yesterdayOrdersCount orders)',
    );
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
      DateTime? orderDate;
      try {
        orderDate = DateTime.parse(order.createdAt.toString());
      } catch (e) {
        continue;
      }

      final orderDateOnly = DateTime(
        orderDate.year,
        orderDate.month,
        orderDate.day,
      );
      final daysDifference = today.difference(orderDateOnly).inDays;

      if (daysDifference >= 0 && daysDifference < 7) {
        final orderTotal = order.totalAmount;
        weeklySales[6 - daysDifference] += orderTotal;
      }
    }

    chartSalesData.value = weeklySales;
    chartLabels.value = labels;
  }

  void _calculateMonthlySalesData() {
    final now = DateTime.now();

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
      final date = DateTime(now.year, now.month - i, 1);
      if (date.month <= 0) {
        labels.add(monthNames[date.month + 12 - 1]);
      } else {
        labels.add(monthNames[date.month - 1]);
      }
    }

    for (var order in allOrders) {
      DateTime? orderDate;
      try {
        orderDate = DateTime.parse(order.createdAt.toString());
      } catch (e) {
        continue;
      }

      final monthsAgo =
          (now.year - orderDate.year) * 12 + (now.month - orderDate.month);

      if (monthsAgo >= 0 && monthsAgo < 12) {
        monthlySales[11 - monthsAgo] += order.totalAmount;
      }
    }

    chartSalesData.value = monthlySales;
    chartLabels.value = labels;
  }

  void _calculateQuarterlySalesData() {
    final now = DateTime.now();

    // Last 4 quarters
    List<double> quarterlySales = List.filled(4, 0.0);
    List<String> labels = [];

    // Generate quarter labels
    for (int i = 3; i >= 0; i--) {
      final quarterDate = DateTime(now.year, now.month - (i * 3), 1);
      final quarter = ((quarterDate.month - 1) ~/ 3) + 1;
      labels.add('Q$quarter ${quarterDate.year.toString().substring(2)}');
    }

    for (var order in allOrders) {
      DateTime? orderDate;
      try {
        orderDate = DateTime.parse(order.createdAt.toString());
      } catch (e) {
        continue;
      }

      final orderQuarter = ((orderDate.month - 1) ~/ 3) + 1;
      final orderYear = orderDate.year;
      final currentQuarter = ((now.month - 1) ~/ 3) + 1;
      final currentYear = now.year;

      int quartersAgo =
          (currentYear - orderYear) * 4 + (currentQuarter - orderQuarter);

      if (quartersAgo >= 0 && quartersAgo < 4) {
        quarterlySales[3 - quartersAgo] += order.totalAmount;
      }
    }

    chartSalesData.value = quarterlySales;
    chartLabels.value = labels;
  }

  void _calculateYearlySalesData() {
    final now = DateTime.now();

    // Last 5 years
    List<double> yearlySales = List.filled(5, 0.0);
    List<String> labels = [];

    // Generate year labels
    for (int i = 4; i >= 0; i--) {
      final year = now.year - i;
      labels.add(year.toString());
    }

    for (var order in allOrders) {
      DateTime? orderDate;
      try {
        orderDate = DateTime.parse(order.createdAt.toString());
      } catch (e) {
        continue;
      }

      final yearsAgo = now.year - orderDate.year;

      if (yearsAgo >= 0 && yearsAgo < 5) {
        yearlySales[4 - yearsAgo] += order.totalAmount;
      }
    }

    chartSalesData.value = yearlySales;
    chartLabels.value = labels;
  }

  void setChartPeriod(ChartPeriod period) {
    selectedChartPeriod.value = period;
    _calculateChartSalesData();
  }

  /// Select an outlet
  void selectOutlet(OutletData outlet) {
    final previousOutlet = appPref.selectedOutlet;

    appPref.selectedOutlet = outlet;
    selectedOutlet.value = outlet; // Update observable
    debugPrint('🏪 Outlet selected: ${outlet.businessName}');

    // Only reload data if outlet actually changed
    if (previousOutlet?.id != outlet.id) {
      onOutletChanged();
    }
    Get.back();
  }

  /// Called when outlet changes - reload all outlet-specific data
  void onOutletChanged() {
    // debugPrint('🔄 Outlet changed, reloading data...');

    // // Reset data
    // allOrders.clear();
    // todaySales.value = 0.0;
    // yesterdaySales.value = 0.0;
    // todayOrders.value = 0;
    // yesterdayOrders.value = 0;
    // weeklySalesData.value = List.filled(7, 0.0);

    // // Reload orders for new outlet
    // getOrderList();

    Get.offAllNamed(AppRoute.homeMain);

    update(); // Update GetBuilder widgets
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
      showError(description: 'Failed to refresh outlets');
    }
  }

  /// Logout
  Future<void> logout() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout'),
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

      // hideLoading();

      Get.offAllNamed(AppRoute.login); // Navigate to login screen

      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    }
  }

  void showOutletBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      isDismissible: true,
      enableDrag: true,
      builder: (context) => OutletBottomSheet(),
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
