import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/Database/app_database.dart' as dbs;
import 'package:billkaro/app/modules/AddOrder/confirm_order_bottomsheet.dart';
import 'package:billkaro/app/modules/AddOrder/quick_addItem_bottomsheet.dart';
import 'package:billkaro/app/modules/BusinessOverview/business_overview_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_controller.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart'
    as api;
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/services/ai/menu_ai_scanner.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/app/services/sync/sync_manager.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:billkaro/utils/kot_print_tracker.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';
import 'dart:async';
import 'dart:io';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Invoice/invoice_controller.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';

enum PosOrderAction { kot, hold, bill }

class AddOrderController extends BaseController {
  // Controllers
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();

  // Image picker for AI menu scanning
  final ImagePicker _imagePicker = ImagePicker();
  final MenuAIScanner _aiScanner = MenuAIScanner();
  var isScanningAI = false.obs;

  // Dependencies (MenuItemController put in onInit if not already registered)
  late final MenuItemController menuItemController;
  final homeController = Get.find<HomeScreenController>();
  final db = Get.find<dbs.AppDatabase>();
  HoldOrdersController? holdOrderController;

  // Pagination variables
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 50.obs;
  final RxBool hasMoreItems = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryId = 'none'.obs;

  // State
  final RxMap<String, int> itemQuantities = <String, int>{}.obs;

  /// Per-line remarks (itemId → note), sent as `itemRemark` on each order item.
  final RxMap<String, String> itemRemarks = <String, String>{}.obs;
  final RxString selectedTaxOption = 'Without Tax'.obs;
  final RxString selectedGSTRate = 'None'.obs;
  final RxString selectedOrderSource = ''.obs;

  final RxList<ItemData> items = <ItemData>[].obs;
  final RxList<ItemData> recommendedItems = <ItemData>[].obs;
  final RxList<CategoryData> categories = <CategoryData>[].obs;

  // Map to store all items for lookup (persists across category changes)
  final RxMap<String, ItemData> allItemsMap = <String, ItemData>{}.obs;

  /// Quantities already sent to kitchen (for incremental KOT like Petpooja).
  final Map<String, int> kotPrintedQuantities = <String, int>{};

  final RxBool showSearchBar = false.obs;
  final RxDouble subtotal = 0.0.obs;
  final RxDouble totalTax = 0.0.obs;
  final RxDouble totalAmount = 0.0.obs;
  final RxDouble gstRate = 0.0.obs;
  api.OrderModel? orders;
  RxBool isKOT = false.obs;

  /// KOT UI and printing only for cafe/restaurant when preference is on.
  bool get isKotFeatureActive =>
      isKOT.value && HomeMainRoutes.outletIsCafeOrRestaurant();
  final RxBool isEdit = false.obs;
  RxBool isListView = false.obs;
  late final RxBool showAddDetailsOnCreateOrder;
  final RxBool isFromTableScreen = false.obs;
  final RxList<TableModel> availableTables = <TableModel>[].obs;
  final RxBool isLoadingTables = false.obs;

  var selectedCategory = 'none'.obs;
  String category = 'none';

  List<String> ordersList = [
    'Delivery',
    "Dine In",
    'Swiggy',
    'Takeaway',
    'Zomato',
  ];
  Map<String, dynamic> orderDetails = {};
  // Trigger UI rebuilds when non-reactive orderDetails map changes.
  final RxInt orderDetailsVersion = 0.obs;

  Timer? _searchDebounce;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? 0}') ?? 0.0;
  }

  void setOrderDetails(Map<String, dynamic> details) {
    orderDetails = details;
    orderDetailsVersion.value++;
    calculateTotals();
  }

  void clearOrderDraft() {
    itemQuantities.clear();
    itemRemarks.clear();
    kotPrintedQuantities.clear();
    orderDetails.clear();
    orders = null;
    isEdit.value = false;
    selectedOrderSource.value = '';
    subtotal.value = 0.0;
    totalTax.value = 0.0;
    totalAmount.value = 0.0;
    orderDetailsVersion.value++;
  }

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<MenuItemController>()) {
      Get.put(MenuItemController());
    }
    menuItemController = Get.find<MenuItemController>();

    // Prefer Modular route args for Modular navigation flows (pushNamed/navigate),
    // and fall back to Get.arguments for legacy GetX navigations.
    final dynamic modularArgs = Modular.args.data;
    final args = (modularArgs is Map<String, dynamic>)
        ? modularArgs
        : (Get.arguments as Map<String, dynamic>?);
    isKOT.value = appPref.isKOT;
    isListView.value = appPref.isListView;
    showAddDetailsOnCreateOrder = appPref.showAddDetailsOnCreateOrder.obs;

    if (args != null) {
      isEdit.value = args['isEdit'] ?? false;
      orders = args['order'];
      isFromTableScreen.value =
          args['fromTables'] == true ||
          (args['tableNumber']?.toString().trim().isNotEmpty ?? false) ||
          (isEdit.value && (orders?.tableNumber?.trim().isNotEmpty ?? false));

      if (orders != null) {
        selectedOrderSource.value = orders!.orderFrom ?? '';
        orderDetails
          ..['id'] = orders!.id
          ..['billNumber'] = orders!.billNumber
          ..['userId'] = orders!.userId
          ..['tableNumber'] = orders!.tableNumber
          ..['customerName'] = orders!.customerName
          ..['phoneNumber'] = orders!.phoneNumber
          ..['discount'] = orders!.discount ?? 0.0
          ..['serviceCharge'] = orders!.serviceCharge ?? 0.0
          ..['paymentReceivedIn'] = orders!.paymentReceivedIn ?? ''
          ..['status'] = orders!.status;
        if (orders!.specialInstructions?.trim().isNotEmpty ?? false) {
          remarkController.text = orders!.specialInstructions!.trim();
        }
      } else {
        // Handle new order with table number from table selection
        if (args['orderFrom'] != null) {
          selectedOrderSource.value = args['orderFrom'];
        }
        if (args['tableNumber'] != null) {
          orderDetails['tableNumber'] = args['tableNumber'];
        }
      }
    }
  }

  @override
  void onReady() async {
    super.onReady();

    if (isEdit.value && !Get.isRegistered<HoldOrdersController>()) {
      Get.lazyPut(() => HoldOrdersController());
    }

    await getCategories();
    await getItems();
    await loadRecommendedItems();
    if (HomeMainRoutes.outletShowsTables()) {
      await loadAvailableTables();
    }

    if (isEdit.value && orders != null) {
      _loadOrderForEdit();
      await _syncKotPrintedFromStorage();
    } else {
      // Petpooja-style: order type tabs in UI — no blocking dialog.
      if (selectedOrderSource.value.isEmpty) {
        selectedOrderSource.value = HomeMainRoutes.outletIsCafeOrRestaurant()
            ? 'Dine In'
            : 'Takeaway';
      }
    }
  }

  void _loadOrderForEdit() {
    itemQuantities.clear();
    itemRemarks.clear();

    for (final item in orders!.items) {
      itemQuantities[item.itemId] = item.quantity ?? 1;
      final remark = item.itemRemark?.trim();
      if (remark != null && remark.isNotEmpty) {
        itemRemarks[item.itemId] = remark;
      }
    }

    calculateTotals();
  }

  Future<void> _syncKotPrintedFromStorage() async {
    if (isEdit.value && orders != null) {
      final hasServerKot = orders!.items.any(
        (item) => item.kotSentQuantity > 0,
      );
      if (hasServerKot) {
        kotPrintedQuantities.clear();
        for (final item in orders!.items) {
          if (item.kotSentQuantity > 0) {
            kotPrintedQuantities[item.itemId] = item.kotSentQuantity;
          }
        }
        return;
      }
    }

    final outletId = appPref.selectedOutlet?.id;
    final orderId = orders?.id ?? orderDetails['id']?.toString();
    if (outletId == null || orderId == null || orderId.isEmpty) {
      if (isEdit.value && orders != null) {
        for (final item in orders!.items) {
          kotPrintedQuantities[item.itemId] = item.kotSentQuantity;
        }
      }
      return;
    }

    final saved = await KotPrintTracker.loadPrintedQuantities(
      outletId,
      orderId,
    );
    if (saved.isNotEmpty) {
      kotPrintedQuantities
        ..clear()
        ..addAll(saved);
      return;
    }

    if (isEdit.value && orders != null) {
      for (final item in orders!.items) {
        kotPrintedQuantities[item.itemId] = item.kotSentQuantity;
      }
    }
  }

  /// Items with quantity not yet sent to kitchen on this order.
  List<OrderItem> buildKotDeltaItems() {
    final delta = <OrderItem>[];
    for (final entry in itemQuantities.entries) {
      final qty = entry.value;
      if (qty < 1) continue;

      final sent = kotPrintedQuantities[entry.key] ?? 0;
      final diff = qty - sent;
      if (diff <= 0) continue;

      final item = allItemsMap[entry.key];
      if (item == null) continue;

      delta.add(_cartOrderItem(entry.key, diff));
    }
    return delta;
  }

  Future<String> _nextKotNumber(String billNumber) async {
    final outletId = appPref.selectedOutlet?.id ?? '';
    return KotPrintTracker.nextKotLabel(outletId, billNumber);
  }

  /// Call after a successful manual KOT print so the same items are not re-sent.
  Future<void> commitKitchenSentQuantities({String? orderId}) =>
      _commitKotPrintedBaseline(orderId: orderId);

  Future<void> _commitKotPrintedBaseline({String? orderId}) async {
    for (final entry in itemQuantities.entries) {
      if (entry.value >= 1) {
        kotPrintedQuantities[entry.key] = entry.value;
      }
    }

    final outletId = appPref.selectedOutlet?.id;
    final resolvedOrderId =
        orderId ?? orders?.id ?? orderDetails['id']?.toString();
    if (outletId != null &&
        resolvedOrderId != null &&
        resolvedOrderId.isNotEmpty) {
      await KotPrintTracker.savePrintedQuantities(
        outletId,
        resolvedOrderId,
        kotPrintedQuantities,
      );
    }
  }

  /// Marks pending cart lines as sent to kitchen (for KDS + kotSentQuantity sync).
  Future<void> _markPendingItemsAsSentToKitchen() async {
    for (final entry in itemQuantities.entries) {
      if (entry.value < 1) continue;
      final sent = kotPrintedQuantities[entry.key] ?? 0;
      if (entry.value > sent) {
        kotPrintedQuantities[entry.key] = entry.value;
      }
    }
  }

  bool _shouldSendToKitchen({
    required bool skipKotPrint,
    required bool requireKotPrint,
    required bool hadKitchenDelta,
  }) {
    if (!isKotFeatureActive) return false;
    if (requireKotPrint) return true;
    if (skipKotPrint) return false;
    return hadKitchenDelta;
  }

  Future<void> _syncKitchenQuantitiesToServer(
    String orderId,
    CreateorderRequest request,
  ) async {
    final kotPayload = _buildCartPayload();
    final response = await callApi(
      apiClient.updateOrder(orderId, {
        ...request.toJson(),
        'items': kotPayload.map((e) => e.toJson()).toList(),
      }),
      showLoader: false,
    );
    if (response == null || response['status'] != 'success') {
      debugPrint('⚠️ Kitchen sync to server failed for order $orderId');
    }
  }

  // Load order data when editing
  void _loadOrderDataForEdit() {
    if (orders == null) return;

    // Clear existing quantities
    itemQuantities.clear();

    // Populate quantities from order items
    for (final orderItem in orders!.items) {
      final itemId = orderItem.itemId;
      final quantity = orderItem.quantity ?? 1;

      itemQuantities[itemId] = quantity;
    }

    // Recalculate totals
    calculateTotals();

    debugPrint('Loaded ${itemQuantities.length} items for editing');
  }

  // --------------------
  // Search & category
  // --------------------
  void showSearchBarFunction() => showSearchBar.value = !showSearchBar.value;

  void clearSearch() {
    _searchDebounce?.cancel();
    searchQuery.value = '';
    currentPage.value = 1;
    items.clear();
    hasMoreItems.value = true;
    getItems();
  }

  void filterItemsBySearch(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    items.clear();
    hasMoreItems.value = true;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      getItems(isFromSearch: true);
    });
  }

  void selectCategory(String? categoryId) {
    selectedCategory.value = categoryId ?? 'none';
    selectedCategoryId.value = categoryId ?? 'none';
    currentPage.value = 1;
    items.clear();
    hasMoreItems.value = true;
    getItems();
  }

  // Load more items (called when scrolling)
  Future<void> loadMoreItems() async {
    if (isLoadingMore.value || !hasMoreItems.value) return;

    currentPage.value++;
    await getItems(append: true);
  }

  // Reset pagination
  void resetPagination() {
    currentPage.value = 1;
    items.clear();
    hasMoreItems.value = true;
  }

  /// Reload categories/items after the global outlet changes (other tabs stay mounted).
  Future<void> reloadForOutletChange() async {
    clearOrderDraft();
    resetPagination();
    allItemsMap.clear();
    categories.clear();
    selectedCategoryId.value = 'none';
    selectedCategory.value = 'none';
    searchQuery.value = '';
    await getCategories();
    await getItems();
  }

  // --------------------
  // Quantity management
  // --------------------
  int getItemQuantity(String itemId) => itemQuantities[itemId] ?? 0;

  void incrementItemQuantity(String itemId) {
    itemQuantities[itemId] = (itemQuantities[itemId] ?? 0) + 1;
    calculateTotals();
  }

  void decrementItemQuantity(String itemId) {
    final current = itemQuantities[itemId] ?? 0;
    if (current <= 1) {
      itemQuantities.remove(itemId);
      itemRemarks.remove(itemId);
    } else {
      itemQuantities[itemId] = current - 1;
    }
    calculateTotals();
  }

  void removeItemCompletely(String itemId) {
    itemQuantities.remove(itemId);
    itemRemarks.remove(itemId);
    calculateTotals();
  }

  String? _itemRemarkFor(String itemId) {
    final remark = itemRemarks[itemId]?.trim();
    if (remark == null || remark.isEmpty) return null;
    return remark;
  }

  OrderItem _cartOrderItem(
    String itemId,
    int quantity, {
    int kotSentQuantity = 0,
  }) {
    final item = allItemsMap[itemId]!;
    return OrderItem(
      itemId: item.id,
      itemName: item.itemName,
      category: item.category,
      quantity: quantity,
      salePrice: item.salePrice,
      gst: item.gst.toDouble(),
      kotSentQuantity: kotSentQuantity,
      itemRemark: _itemRemarkFor(itemId),
    );
  }

  /// Get count of selected items (items with quantity >= 1)
  int get selectedItemsCount {
    return itemQuantities.values.where((qty) => qty >= 1).length;
  }

  /// Get total quantity of all selected items
  int get totalSelectedQuantity {
    return itemQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  /// Check if there are any selected items
  bool get hasSelectedItems => selectedItemsCount > 0;

  int get pendingKotItemCount {
    var count = 0;
    for (final entry in itemQuantities.entries) {
      if (entry.value < 1) continue;
      final sent = kotPrintedQuantities[entry.key] ?? 0;
      final diff = entry.value - sent;
      if (diff > 0) count += diff;
    }
    return count;
  }

  String get displayBillNumber {
    final bill = orderDetails['billNumber']?.toString().trim();
    if (bill != null && bill.isNotEmpty) return bill;
    return isEdit.value ? '—' : 'New';
  }

  Future<void> loadAvailableTables() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    isLoadingTables.value = true;
    try {
      final response = await callApi(
        apiClient.getOutletTables(outletId),
        showLoader: false,
      );
      if (response?.status == 'success') {
        availableTables.value = response!.data
            .map((e) => TableModel.fromTableData(e))
            .toList();
      }
    } catch (_) {
      // Tables optional for non-restaurant outlets.
    } finally {
      isLoadingTables.value = false;
    }
  }

  void setOrderSource(String source) {
    selectedOrderSource.value = source;
    if (source.trim().toLowerCase() != 'dine in') {
      if (!isEdit.value && !isFromTableScreen.value) {
        orderDetails.remove('tableNumber');
        orderDetailsVersion.value++;
      }
    } else if (HomeMainRoutes.outletShowsTables() && availableTables.isEmpty) {
      loadAvailableTables();
    }
  }

  void setTableNumber(String? table) {
    if (table == null || table.trim().isEmpty) {
      orderDetails.remove('tableNumber');
    } else {
      orderDetails['tableNumber'] = table.trim();
    }
    orderDetailsVersion.value++;
  }

  Future<bool> ensureBillDetails() async {
    final payment = (orderDetails['paymentReceivedIn'] ?? '').toString().trim();
    if (payment.isNotEmpty) return true;

    final result = await Modular.to.pushNamed(
      HomeMainRoutes.orderDetails,
      arguments: {
        ...orderDetails,
        'orderFrom': selectedOrderSource.value,
        'tableNumber': orderDetails['tableNumber'] ?? '',
        'totalAmount': totalAmount.value,
        'requirePayment': true,
      },
    );
    if (result != null && result is CreateorderRequest) {
      setOrderDetails(result.toJson());
      return true;
    }
    return false;
  }

  /// Petpooja-style POS: KOT stays on screen; Hold saves & exits; Bill settles.
  Future<void> executePosAction(PosOrderAction action) async {
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

    if (itemQuantities.isEmpty) {
      showError(description: AppLocalizations.of(Get.context!)!.add_items);
      return;
    }

    if (action == PosOrderAction.bill) {
      final ready = await ensureBillDetails();
      if (!ready) return;
    } else if (appPref.showAddDetailsOnCreateOrder &&
        orderDetails.isEmpty &&
        action != PosOrderAction.kot) {
      showError(description: 'Please enter the order details');
      return;
    }

    if (action == PosOrderAction.kot && isKotFeatureActive) {
      if (pendingKotItemCount == 0) {
        showError(description: 'No new items to send to kitchen');
        return;
      }
      await showRemarkDialog();
    }

    final status = action == PosOrderAction.bill ? 'closed' : 'pending';
    await saveAndBill(
      status,
      stayOnScreen: action == PosOrderAction.kot && isKotFeatureActive,
      skipKotPrint: action == PosOrderAction.hold,
      requireKotPrint: action == PosOrderAction.kot && isKotFeatureActive,
    );
  }

  void confirmBillAction() {
    final context = Get.context!;
    final loc = AppLocalizations.of(context)!;
    final actionLabel = isKotFeatureActive ? 'KOT & Bill' : loc.save_and_bill;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Settle Bill'),
        content: Text(
          'Confirm $actionLabel for ₹${totalAmount.value.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              executePosAction(PosOrderAction.bill);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  List<OrderItem> _buildCartPayload() {
    final payload = <OrderItem>[];
    for (final e in itemQuantities.entries) {
      if (e.value < 1) continue;
      final item = allItemsMap[e.key];
      if (item == null) continue;

      payload.add(
        _cartOrderItem(
          e.key,
          e.value,
          kotSentQuantity: kotPrintedQuantities[e.key] ?? 0,
        ),
      );
    }
    return payload;
  }

  String? _existingOrderId() {
    final fromDetails = orderDetails['id']?.toString().trim();
    if (fromDetails != null && fromDetails.isNotEmpty) return fromDetails;
    final fromOrder = orders?.id.trim();
    if (fromOrder != null && fromOrder.isNotEmpty) return fromOrder;
    return null;
  }

  Future<void> _enterEditModeAfterSave({
    required Map<String, dynamic> responseData,
    required CreateorderRequest request,
  }) async {
    final savedId = responseData['id']?.toString();
    if (savedId == null || savedId.isEmpty) return;

    isEdit.value = true;
    orderDetails['id'] = savedId;
    orderDetails['billNumber'] =
        responseData['billNumber']?.toString() ?? request.billNumber;
    orderDetails['status'] = 'pending';
    orderDetailsVersion.value++;

    orders = _mapToOrderModel(
      CreateorderRequest(
        billNumber:
            responseData['billNumber']?.toString() ?? request.billNumber,
        userId: request.userId,
        outletId: request.outletId,
        tableNumber: request.tableNumber,
        customerName: request.customerName,
        phoneNumber: request.phoneNumber,
        subtotal: request.subtotal,
        totalTax: request.totalTax,
        discount: request.discount,
        serviceCharge: request.serviceCharge,
        totalAmount: request.totalAmount,
        paymentReceivedIn: request.paymentReceivedIn,
        splitPayments: request.splitPayments,
        status: 'pending',
        orderFrom: request.orderFrom,
        items: _buildCartPayload(),
        specialInstructions: request.specialInstructions,
      ),
      savedId,
      statusOverride: 'pending',
    );
  }

  // --------------------
  // Utility
  // --------------------
  String formatOrderTime(String isoTime) {
    final dateTime = DateTime.tryParse(isoTime) ?? DateTime.now();
    return formatDateTimeForDisplay(dateTime, 'dd MMM yyyy, hh:mm a');
  }

  Widget showIcon() {
    switch (selectedOrderSource.value) {
      case 'Delivery':
        return Assets.delivery.image(width: 24, height: 24);
      case 'Dine In':
        return Assets.dineIn.image(width: 24, height: 24);
      case 'Swiggy':
        return Assets.svg.swiggy.svg(width: 24, height: 24);
      case 'Takeaway':
        return Assets.takeaway.image(width: 24, height: 24);
      case 'Zomato':
        return Assets.svg.zomato.svg(width: 24, height: 24);
      default:
        return const Icon(Icons.help_outline);
    }
  }

  // --------------------
  // Order source dialog
  // --------------------
  void _showOrderSourceDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Material(
          color: Colors.transparent,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: MediaQuery.of(Get.context!).size.width * 0.4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Close the dialog...
                            Get.back();
                            // ...and always return to the Home tab in the shell.
                            Modular.to.navigate(HomeMainRoutes.home);
                          },
                          child: const Icon(Icons.close, size: 24),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: ordersList.map((source) {
                            Widget iconData;
                            switch (source) {
                              case 'Delivery':
                                iconData = Assets.delivery.image(
                                  width: 24,
                                  height: 24,
                                );
                                break;
                              case 'Dine In':
                                iconData = Assets.dineIn.image(
                                  width: 24,
                                  height: 24,
                                );
                                break;
                              case 'Swiggy':
                                iconData = Assets.svg.swiggy.svg(
                                  width: 24,
                                  height: 24,
                                );
                                break;
                              case 'Takeaway':
                                iconData = Assets.takeaway.image(
                                  width: 24,
                                  height: 24,
                                );
                                break;
                              case 'Zomato':
                                iconData = Assets.svg.zomato.svg(
                                  width: 24,
                                  height: 24,
                                );
                                break;
                              default:
                                iconData = const Icon(Icons.help_outline);
                            }
                            return SizedBox(
                              width: itemWidth,
                              child: _buildOrderSourceOption(source, iconData),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildOrderSourceOption(String label, Widget icon) {
    return GestureDetector(
      onTap: () {
        selectedOrderSource.value = label;
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            icon,
          ],
        ),
      ),
    );
  }

  // --------------------
  // Add item (quick)
  // --------------------

  /// Open camera/gallery, scan menu with AI, then show quick add bottom sheet
  Future<void> addMenuUsingAI() async {
    try {
      // Show image source selection dialog
      final imageSource = await _showImageSourceDialog();
      if (imageSource == null) return;

      String? capturedPath;
      if (imageSource == ImageSource.camera) {
        if (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
          capturedPath = await showDesktopCameraCaptureDialog();
        } else {
          final XFile? image = await _imagePicker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1800,
            maxHeight: 1800,
            imageQuality: 85,
          );
          capturedPath = image?.path;
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        capturedPath = image?.path;
      }

      if (capturedPath == null) return;

      // Show loading
      isScanningAI.value = true;
      showAppLoader();

      // Scan with AI
      debugPrint('🤖 [AI] Starting AI scan for quick add...');
      final result = await _aiScanner.scanMenuFromPhoto(File(capturedPath));

      dismissAppLoader();
      isScanningAI.value = false;

      if (result.isValid) {
        // Auto-fill form fields with AI results
        if (result.itemName.isNotEmpty) {
          itemNameController.text = result.itemName;
        }

        if (result.price != null) {
          salePriceController.text = result.price!.toStringAsFixed(2);
        }

        // Show success message
        showSuccess(
          description:
              'AI scan completed! Found: ${result.itemName}${result.price != null ? " - ₹${result.price}" : ""}',
        );

        // Show quick add bottom sheet with pre-filled data
        showQuickAddItemBottomSheet();
      } else {
        // Still show bottom sheet even if AI scan failed
        showQuickAddItemBottomSheet();
        showError(
          description:
              'Could not extract menu information. Please enter manually.',
        );
      }
    } catch (e) {
      dismissAppLoader();
      isScanningAI.value = false;
      debugPrint('❌ [AI] Error in addMenuUsingAI: $e');
      showError(description: 'Failed to scan menu: ${e.toString()}');
      // Still show bottom sheet on error
      showQuickAddItemBottomSheet();
    }
  }

  /// Show dialog to select image source (camera or gallery)
  Future<ImageSource?> _showImageSourceDialog() async {
    final bool isWindowsDesktop = Platform.isWindows;
    final double screenWidth = MediaQuery.of(Get.context!).size.width;
    final double dialogWidth = isWindowsDesktop
        ? (screenWidth * 0.35).clamp(320.0, 480.0)
        : (screenWidth * 0.9).clamp(280.0, 420.0);
    return await Get.dialog<ImageSource>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: dialogWidth,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(result: ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColor.primary, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: AppColor.primary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Camera',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isWindowsDesktop) ...[
                              const SizedBox(height: 4),
                              Text(
                                'USB / webcam',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(result: ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColor.primary, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isWindowsDesktop
                                  ? Icons.folder_open_outlined
                                  : Icons.photo_library,
                              size: 32,
                              color: AppColor.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isWindowsDesktop ? 'Browse Files' : 'Gallery',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void addItem(String itemCategory) {
    category = itemCategory;
    showQuickAddItemBottomSheet();
  }

  void showQuickAddItemBottomSheet() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickAddItemBottomSheet(),
    );
  }

  bool _isConfirmOrderBottomSheetOpen = false;

  /// Review items in a bottom sheet, then confirm Save or Bill.
  void showConfirmOrderBottomSheet(PosOrderAction action) {
    if (action != PosOrderAction.hold && action != PosOrderAction.bill) return;
    if (_isConfirmOrderBottomSheetOpen) return;

    final loc = AppLocalizations.of(Get.context!)!;
    if (itemQuantities.isEmpty) {
      showError(description: loc.add_items);
      return;
    }
    if (appPref.showAddDetailsOnCreateOrder && orderDetails.isEmpty) {
      showError(description: 'Please enter the order details');
      return;
    }
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

    _isConfirmOrderBottomSheetOpen = true;
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConfirmOrderBottomSheet(action: action),
    ).whenComplete(() => _isConfirmOrderBottomSheetOpen = false);
  }

  void selectTaxOption(String option) => selectedTaxOption.value = option;

  void selectGSTRate(String rate, double value) {
    selectedGSTRate.value = rate;
    gstRate.value = value;
  }

  Future<void> onAddItem() async {
    final name = itemNameController.text.trim();
    final priceParsed = double.tryParse(salePriceController.text.trim());

    final loc = AppLocalizations.of(Get.context!)!;
    if (name.isEmpty) {
      showError(description: loc.please_enter_item_name);
      return;
    }
    if (priceParsed == null) {
      showError(description: loc.please_enter_valid_sale_price);
      return;
    }

    final request = ItemRequest(
      showItem: true,
      outletId: appPref.selectedOutlet!.id!,
      userId: appPref.user!.id!,
      category: category,
      itemName: name,
      salePrice: priceParsed,
      withTax: selectedTaxOption.value == 'With Tax',
      gst: gstRate.value,
      orderFrom: selectedOrderSource.value,
    );

    debugPrint('${gstRate.value} request: ${request.toJson()}');
    final response = await callApi(apiClient.addItem(request));
    if (response != null && response['status'] == 'success') {
      Get.back();
      resetPagination();
      await getItems();
      menuItemController.getItems(showLoader: false);
      category = 'none';
      itemNameController.clear();
      salePriceController.clear();
      selectedTaxOption.value = 'Without Tax';
      selectedGSTRate.value = 'none';
      dismissAllAppLoader();
      final loc = AppLocalizations.of(Get.context!)!;
      showSuccess(
        description: response['message'] ?? loc.item_added_successfully,
      );
    } else {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: response?['message'] ?? loc.failed_to_add_item);
    }
  }

  Future<void> submitItem() async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (itemNameController.text.trim().isEmpty) {
      showError(description: loc.please_enter_item_name);
      return;
    }
    if (salePriceController.text.trim().isEmpty) {
      showError(description: loc.please_enter_valid_sale_price);
      return;
    }
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    await onAddItem();
  }

  static const int _bestSellingLimit = 5;

  bool get showRecommendedSection =>
      selectedCategoryId.value == 'none' && searchQuery.value.isEmpty;

  Set<String> get bestSellingItemIds =>
      recommendedItems.map((item) => item.id).toSet();

  Future<void> loadRecommendedItems() async {
    try {
      final outletId = appPref.selectedOutlet?.id;
      final userId = appPref.user?.id;
      if (outletId == null || userId == null) {
        recommendedItems.clear();
        return;
      }

      final isOnline = await NetworkUtils.hasInternetConnection();
      if (!isOnline) {
        recommendedItems.value = await _loadBestSellingItemsOffline(outletId);
        return;
      }

      final response = await callApi(
        apiClient.getBestSellingItems(userId, outletId, _bestSellingLimit),
        showLoader: false,
      );

      if (response is Map && response['status'] == 'success') {
        final rows = (response['data'] as List?) ?? [];
        final loaded = <ItemData>[];
        for (final row in rows) {
          if (row is! Map) continue;
          final itemJson = row['item'];
          if (itemJson is Map<String, dynamic>) {
            final item = ItemData.fromJson(itemJson);
            loaded.add(item);
            allItemsMap[item.id] = item;
            continue;
          }
          final itemId = row['itemId']?.toString() ?? '';
          if (itemId.isEmpty) continue;
          final cached =
              allItemsMap[itemId] ??
              items.firstWhereOrNull((item) => item.id == itemId);
          if (cached != null) {
            loaded.add(cached);
            allItemsMap[cached.id] = cached;
          }
        }
        recommendedItems.value = loaded;
      } else {
        recommendedItems.clear();
      }
    } catch (e) {
      debugPrint('loadRecommendedItems error: $e');
      recommendedItems.clear();
    }
  }

  Future<List<ItemData>> _loadBestSellingItemsOffline(String outletId) async {
    final db = AppDatabase();
    final page = await db.getOrdersPage(
      outletId: outletId,
      limit: 500,
      offset: 0,
    );
    final qtyByItemId = <String, int>{};
    for (final order in page.items) {
      if (order.status?.toLowerCase() != 'closed') continue;
      for (final line in order.items) {
        final itemId = line.itemId.trim();
        if (itemId.isEmpty) continue;
        qtyByItemId[itemId] = (qtyByItemId[itemId] ?? 0) + line.quantity;
      }
    }
    final sortedIds = qtyByItemId.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final loaded = <ItemData>[];
    for (final entry in sortedIds.take(_bestSellingLimit)) {
      final cached =
          allItemsMap[entry.key] ??
          items.firstWhereOrNull((item) => item.id == entry.key);
      if (cached != null && cached.showItem) {
        loaded.add(cached);
      }
    }
    return loaded;
  }

  // --------------------
  // Fetch data with pagination
  // --------------------
  Future<void> getItems({
    bool append = false,
    bool isFromSearch = false,
  }) async {
    final db = AppDatabase();

    try {
      if (!append) {
        isLoadingMore.value = false;
      } else {
        isLoadingMore.value = true;
      }

      debugPrint(
        '📦 Fetching items - Page: ${currentPage.value}, Limit: ${itemsPerPage.value}',
      );

      final isOnline = await NetworkUtils.hasInternetConnection();

      debugPrint('🌐 isOnline: $isOnline');
      debugPrint('Fetching items for user ID: ${appPref.user!.id}');

      if (isOnline) {
        debugPrint('🌐 Online → Fetching items from API');

        // Prepare category filter
        String? categoryFilter;
        if (selectedCategoryId.value != 'none') {
          categoryFilter = selectedCategoryId.value;
        }

        // Prepare search query
        String? searchFilter;
        if (searchQuery.value.isNotEmpty) {
          searchFilter = searchQuery.value;
        }

        final response = await callApi(
          apiClient.getItems(
            appPref.selectedOutlet!.id!,
            currentPage.value,
            itemsPerPage.value,
            categoryFilter,
            searchFilter,
            true, // showItem - only available items
            null,
          ),
          // Avoid showing full-screen loader for incremental search
          showLoader: !append && !isFromSearch,
        );

        if (response?.status == 'success') {
          final newItems = response!.data ?? [];

          if (append) {
            items.addAll(newItems);
          } else {
            items.value = newItems;
            if (!isFromSearch && selectedCategoryId.value == 'none') {
              await loadRecommendedItems();
            }
          }

          // Add all items to the lookup map for calculating totals across categories
          for (final item in newItems) {
            allItemsMap[item.id] = item;
          }

          // Check if there are more items to load
          if (newItems.length < itemsPerPage.value) {
            hasMoreItems.value = false;
          } else {
            hasMoreItems.value = true;
          }

          // Note: We preserve itemQuantities across category changes
          // so items added in one category remain selected when switching categories

          await calculateTotals();

          debugPrint(
            '✅ Loaded ${newItems.length} items. Total items: ${items.length}',
          );
        } else {
          debugPrint('getItems: unexpected response: $response');
          hasMoreItems.value = false;
        }
      } else {
        debugPrint('🌐 Offline → Fetching items from SQLite');
        final allItems = await db.getItems();

        // Apply filters
        var filteredItems = allItems;

        // Category filter
        if (selectedCategoryId.value != 'none') {
          filteredItems = filteredItems
              .where(
                (item) =>
                    item.category.toLowerCase() ==
                    selectedCategoryId.value.toLowerCase(),
              )
              .toList();
        }

        // Search filter
        if (searchQuery.value.isNotEmpty) {
          filteredItems = filteredItems
              .where(
                (item) => item.itemName.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
        }

        // Apply pagination
        final startIndex = (currentPage.value - 1) * itemsPerPage.value;
        final endIndex = startIndex + itemsPerPage.value;

        if (startIndex < filteredItems.length) {
          final paginatedItems = filteredItems.sublist(
            startIndex,
            endIndex > filteredItems.length ? filteredItems.length : endIndex,
          );

          if (append) {
            items.addAll(paginatedItems);
          } else {
            items.value = paginatedItems;
          }

          // Add all items to the lookup map for calculating totals across categories
          for (final item in filteredItems) {
            allItemsMap[item.id] = item;
          }

          hasMoreItems.value = endIndex < filteredItems.length;
        } else {
          hasMoreItems.value = false;
        }
      }

      isLoadingMore.value = false;
    } catch (e, st) {
      debugPrint('getItems error: $e\n$st');
      isLoadingMore.value = false;
      hasMoreItems.value = false;
    }
  }

  Future<void> getCategories() async {
    try {
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return;

      final loaded = await OfflineCategoryLoader.load(
        outletId: outletId,
        fetchFromApi: () => callApi(apiClient.getCategories(outletId)),
      );
      categories.value = loaded;
      dismissAllAppLoader();
    } catch (e, st) {
      debugPrint('getCategories error: $e\n$st');
    }
  }

  // KOT Bill //

  final TextEditingController remarkController = TextEditingController();

  Future<void> showRemarkDialog() async {
    final loc = AppLocalizations.of(Get.context!)!;
    await Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_note_outlined,
                        color: AppColor.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add remark',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optional note for kitchen or billing',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: Get.back,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: remarkController,
                  autofocus: true,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Enter remark for this order',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColor.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: Get.back,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Get.back(result: remarkController.text.trim());
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(loc.save_remark),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> showItemRemarkDialog(String itemId, String itemName) async {
    final existing = itemRemarks[itemId] ?? '';
    final itemRemarkController = TextEditingController(text: existing);

    final result = await Get.dialog<String>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item remark',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: itemRemarkController,
                  autofocus: true,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'e.g. less spicy, no onion',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(result: ''),
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: Get.back,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          Get.back(result: itemRemarkController.text.trim()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    itemRemarkController.dispose();

    if (result == null) return;
    if (result.isEmpty) {
      itemRemarks.remove(itemId);
    } else {
      itemRemarks[itemId] = result;
    }
    orderDetailsVersion.value++;
  }

  Future<void> showKOTPrintDialog() async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (itemQuantities.isEmpty) {
      showError(description: loc.please_add_items_to_order);
      return;
    }
    if (appPref.showAddDetailsOnCreateOrder && orderDetails.isEmpty) {
      showError(description: loc.please_add_details_to_order);
      return;
    }
    await showRemarkDialog();

    return Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [CloseButton()],
              ),
              const Text(
                'Print KOT?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Do you want to print the KOT for this order?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => getKOTBill(),
                    child: Text(loc.print_kot),
                  ),
                  ElevatedButton(
                    onPressed: () => saveAndBill('closed'),
                    child: Text(loc.print_bill),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> getKOTBill() async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (itemQuantities.isEmpty) {
      showError(description: loc.please_add_items_to_order);
      return;
    }

    final kotItems = isKotFeatureActive
        ? buildKotDeltaItems()
        : _allCartItemsForKot();

    if (kotItems.isEmpty) {
      showError(description: 'No new items to send to kitchen');
      return;
    }

    String kotBillNumber = orderDetails['billNumber']?.toString() ?? '';
    if (kotBillNumber.isEmpty) {
      kotBillNumber = await _generateNextIntegerBillNumber();
    }

    final kotNumber = isKotFeatureActive
        ? await _nextKotNumber(kotBillNumber)
        : kotBillNumber;

    final kotRequest = CreateorderRequest(
      billNumber: kotNumber,
      tableNumber: orderDetails['tableNumber'] ?? '',
      customerName: orderDetails['customerName'] ?? '',
      phoneNumber: orderDetails['phoneNumber'] ?? '',
      discount: (orderDetails['discount'] is num)
          ? (orderDetails['discount'] as num).toDouble()
          : (double.tryParse('${orderDetails['discount'] ?? 0}') ?? 0.0),
      serviceCharge: (orderDetails['serviceCharge'] is num)
          ? (orderDetails['serviceCharge'] as num).toDouble()
          : (double.tryParse('${orderDetails['serviceCharge'] ?? 0}') ?? 0.0),
      paymentReceivedIn: orderDetails['paymentReceivedIn'] ?? '',
      status: orderDetails['status'] ?? 'pending',
      items: kotItems,
      subtotal: subtotal.value,
      totalAmount: totalAmount.value,
      userId: appPref.user!.id,
      orderFrom: selectedOrderSource.value,
      totalTax: totalTax.value,
    );

    Modular.to.pushNamed(
      HomeMainRoutes.kotReceipt,
      arguments: {
        'invoice': kotRequest,
        'orderFrom': selectedOrderSource.value,
        'tableNumber': orderDetails['tableNumber'] ?? '',
        'orderId': orders?.id ?? '',
        'orderStatus': orderDetails['status'] ?? 'pending',
        'isEdit': isEdit.value,
        'specialInstructions': remarkController.text.trim(),
        'billNumber': kotBillNumber,
      },
    );
  }

  List<OrderItem> _allCartItemsForKot() {
    final kotItems = <OrderItem>[];
    for (final entry in itemQuantities.entries) {
      if (entry.value < 1) continue;
      final item = allItemsMap[entry.key];
      if (item == null) continue;
      kotItems.add(_cartOrderItem(entry.key, entry.value));
    }
    return kotItems;
  }

  Future<void> _maybeAutoPrintKOT(
    CreateorderRequest request, {
    String? orderId,
    List<OrderItem>? kotItemsOverride,
  }) async {
    if (!isKotFeatureActive) return;

    final kotItems = kotItemsOverride ?? buildKotDeltaItems();
    if (kotItems.isEmpty) return;

    try {
      final printerService = ThermalPrinterService.instance;
      // Route KOT to the KOT printer (if configured), otherwise user will be
      // prompted to connect and it will be saved as KOT printer automatically.
      final connected = await printerService.ensureConnectedForRole(
        PrintRole.kot,
      );
      if (!connected) {
        debugPrint(
          '⚠️ KOT printer not connected — kitchen display will still update',
        );
        return;
      }

      final billNo =
          orderDetails['billNumber']?.toString() ?? request.billNumber ?? '';
      final kotNumber = await _nextKotNumber(billNo);

      final now = DateTime.now().toString();
      final dateStr = formatDate(now);
      final timeStr = formatTime(now);

      final totalQty = kotItems.fold<int>(0, (sum, i) => sum + i.quantity);

      await printerService.printKOT(
        kotNumber: kotNumber,
        brandName: appPref.user?.brandName ?? '',
        businessName: appPref.user?.outletData?.first.businessName ?? '',
        address: appPref.user?.address ?? '',
        city: appPref.user?.city ?? '',
        zipcode: appPref.user?.zipcode ?? '',
        state: appPref.user?.state ?? '',
        orderFrom: request.orderFrom ?? '',
        tableNumber: request.tableNumber ?? '',
        customerName: request.customerName ?? '',
        waiterName: appPref.user?.brandName ?? 'Staff',
        date: dateStr,
        time: timeStr,
        items: kotItems,
        specialInstructions: remarkController.text.trim(),
        totalQuantity: totalQty,
      );
    } catch (e) {
      debugPrint('⚠️ Auto KOT print failed: $e');
    }
  }

  /// Opens invoice preview from current cart and order details (no save/API).
  Future<void> viewInvoicePreview() async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (itemQuantities.isEmpty) {
      showError(description: loc.please_add_items_to_order);
      return;
    }

    if (_requiresDineInTable()) {
      final tableNumber = (orderDetails['tableNumber'] ?? '').toString().trim();
      if (tableNumber.isEmpty) {
        showError(description: 'Please select a table for Dine In order');
        return;
      }
    }

    final List<OrderItem> payload = [];

    for (final e in itemQuantities.entries) {
      final item = allItemsMap[e.key];
      if (item == null) continue;

      payload.add(_cartOrderItem(e.key, e.value));
    }

    if (payload.isEmpty) {
      showError(description: loc.please_add_items_to_order);
      return;
    }

    String? finalBillNumber;
    if (isEdit.value) {
      finalBillNumber = orderDetails['billNumber']?.toString();
    } else {
      if (orderDetails['billNumber'] != null &&
          orderDetails['billNumber'].toString().isNotEmpty) {
        finalBillNumber = orderDetails['billNumber'].toString();
      } else {
        finalBillNumber = await _generateNextIntegerBillNumber();
      }

      final billStr = finalBillNumber;
      final billNumInt = int.tryParse(billStr);
      if (billNumInt == null) {
        finalBillNumber = await _generateNextIntegerBillNumber();
      } else {
        final isUnique = await _isBillNumberUnique(billStr);
        if (!isUnique) {
          finalBillNumber = await _generateNextIntegerBillNumber();
        }
      }
    }

    List<SplitPayment>? splitPaymentsList;
    if (orderDetails['splitPayments'] != null) {
      if (orderDetails['splitPayments'] is List) {
        final List<dynamic> splitList = orderDetails['splitPayments'];
        splitPaymentsList = splitList
            .map((json) => SplitPayment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    final request = CreateorderRequest(
      billNumber: finalBillNumber,
      userId: appPref.user!.id,
      outletId: appPref.selectedOutlet!.id!,
      tableNumber: orderDetails['tableNumber'] ?? '',
      customerName: orderDetails['customerName'] ?? '',
      phoneNumber: orderDetails['phoneNumber'] ?? '',
      discount: _asDouble(orderDetails['discount']),
      serviceCharge: _asDouble(orderDetails['serviceCharge']),
      paymentReceivedIn: orderDetails['paymentReceivedIn'],
      splitPayments: splitPaymentsList,
      status: 'pending',
      orderFrom: selectedOrderSource.value,
      subtotal: subtotal.value,
      totalTax: totalTax.value,
      totalAmount: totalAmount.value,
      items: payload,
    );

    if (Get.isRegistered<InvoicePreviewController>()) {
      Get.delete<InvoicePreviewController>(force: true);
    }

    await Modular.to.pushNamed(
      HomeMainRoutes.invoiceScreen,
      arguments: {
        'invoice': request,
        'orderFrom': selectedOrderSource.value,
        'isEdit': isEdit.value,
        'isOffline': false,
      },
    );
  }

  // --------------------
  // Save & Bill (with Edit support)
  // --------------------

  Future<void> saveAndBill(
    String status, {
    bool stayOnScreen = false,
    bool skipKotPrint = false,
    bool requireKotPrint = false,
  }) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final normalizedStatus = status.trim().toLowerCase();
    // API expects 'pending' for billing flow, but the app UI/table status relies on
    // local order status. So keep a separate local status for correct table state.
    final localStatusForUi = normalizedStatus;
    final orderStatusForApi = normalizedStatus == 'billing'
        ? 'pending'
        : normalizedStatus;
    final isBilling =
        normalizedStatus == 'closed' || normalizedStatus == 'billing';
    final isHoldOnly = !isBilling && skipKotPrint;

    if (requireKotPrint && buildKotDeltaItems().isEmpty) {
      showError(description: 'No new items to send to kitchen');
      return;
    }

    if (isKotFeatureActive &&
        !skipKotPrint &&
        buildKotDeltaItems().isNotEmpty &&
        !requireKotPrint) {
      await showRemarkDialog();
    }

    if (itemQuantities.isEmpty) {
      showError(description: loc.add_items);
      return;
    }

    if (_requiresDineInTable()) {
      final tableNumber = (orderDetails['tableNumber'] ?? '').toString().trim();
      if (tableNumber.isEmpty) {
        showError(description: 'Please select a table for Dine In order');
        return;
      }

      if (!isEdit.value) {
        final hasConflict = await _hasAnotherActiveOrderOnTable(tableNumber);
        if (hasConflict) {
          showError(description: 'This table already has an active order');
          return;
        }
      }
    }

    final kotDeltaForPrint = buildKotDeltaItems();
    final hadKitchenDelta = kotDeltaForPrint.isNotEmpty;
    final sendToKitchen = _shouldSendToKitchen(
      skipKotPrint: skipKotPrint,
      requireKotPrint: requireKotPrint,
      hadKitchenDelta: hadKitchenDelta,
    );
    final shouldTryKotPrint =
        isKotFeatureActive && !skipKotPrint && hadKitchenDelta;

    if (sendToKitchen) {
      await _markPendingItemsAsSentToKitchen();
    }

    final payload = _buildCartPayload();

    String? finalBillNumber;
    if (isEdit.value) {
      finalBillNumber = orderDetails['billNumber']?.toString().trim();
      if (finalBillNumber == null || finalBillNumber.isEmpty) {
        finalBillNumber = orders?.billNumber;
      }
    } else {
      if (orderDetails['billNumber'] != null &&
          orderDetails['billNumber'].toString().isNotEmpty) {
        finalBillNumber = orderDetails['billNumber'].toString();
      } else {
        finalBillNumber = await _generateNextIntegerBillNumber();
      }

      if (finalBillNumber != null) {
        final billNumInt = int.tryParse(finalBillNumber);
        if (billNumInt == null) {
          finalBillNumber = await _generateNextIntegerBillNumber();
        } else {
          final isUnique = await _isBillNumberUnique(finalBillNumber);
          if (!isUnique) {
            finalBillNumber = await _generateNextIntegerBillNumber();
            debugPrint(
              '🔄 Generated unique integer bill number: $finalBillNumber',
            );
          }
        }
      }
    }

    List<SplitPayment>? splitPaymentsList;
    if (orderDetails['splitPayments'] != null) {
      if (orderDetails['splitPayments'] is List) {
        final List<dynamic> splitList = orderDetails['splitPayments'];
        splitPaymentsList = splitList
            .map((json) => SplitPayment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    final request = CreateorderRequest(
      billNumber: finalBillNumber,
      userId: appPref.user!.id,
      outletId: appPref.selectedOutlet!.id!,
      tableNumber: orderDetails['tableNumber'] ?? '',
      customerName: orderDetails['customerName'] ?? '',
      phoneNumber: orderDetails['phoneNumber'] ?? '',
      discount: _asDouble(orderDetails['discount']),
      serviceCharge: _asDouble(orderDetails['serviceCharge']),
      paymentReceivedIn: orderDetails['paymentReceivedIn'],
      splitPayments: splitPaymentsList,
      status: orderStatusForApi,
      orderFrom: selectedOrderSource.value,
      subtotal: subtotal.value,
      totalTax: totalTax.value,
      totalAmount: totalAmount.value,
      items: payload,
      specialInstructions: remarkController.text.trim().isEmpty
          ? null
          : remarkController.text.trim(),
    );

    final shouldPrintKot = shouldTryKotPrint;

    final hasInternet = await NetworkUtils.hasInternetConnection();

    final existingOrderId = _existingOrderId();
    final shouldUpdate =
        isEdit.value && existingOrderId != null && existingOrderId.isNotEmpty;

    if (hasInternet) {
      final response = shouldUpdate
          ? await callApi(
              apiClient.updateOrder(existingOrderId!, request.toJson()),
            )
          : await callApi(apiClient.addOrder(request.toJson()));

      if (response != null && response['status'] == 'success') {
        final savedId =
            response['data']?['id']?.toString() ?? existingOrderId ?? '';
        if (savedId.isEmpty) {
          showError(description: loc.order_failed);
          return;
        }

        final orderModel = _mapToOrderModel(
          request,
          savedId,
          statusOverride: localStatusForUi,
        );

        await db.insertOrders(
          [orderModel],
          appPref.selectedOutlet!.id!,
          isSyncedFromApi: true,
        );

        await _syncTableStatusForDineInOrder(
          orderStatus: normalizedStatus,
          tableNumber: request.tableNumber,
          currentBillNumber: response['data']?['billNumber']?.toString(),
        );

        await homeController.getOrderList(forceApiRefresh: true);
        if (Get.isRegistered<BusinessOverviewController>()) {
          await Get.find<BusinessOverviewController>().getOrderList(
            forceApiRefresh: true,
          );
        }

        final savedOrderId = savedId;
        orderDetails['id'] = savedOrderId;
        if (response['data']?['billNumber'] != null) {
          orderDetails['billNumber'] = response['data']['billNumber']
              .toString();
        }

        if (sendToKitchen) {
          if (shouldPrintKot) {
            await _maybeAutoPrintKOT(
              request,
              orderId: savedOrderId,
              kotItemsOverride: kotDeltaForPrint,
            );
          }
          await _commitKotPrintedBaseline(orderId: savedOrderId);
          await _syncKitchenQuantitiesToServer(savedOrderId, request);
        }

        if (stayOnScreen) {
          await _enterEditModeAfterSave(
            responseData: response['data'] ?? {},
            request: request,
          );
          await _refreshTablesAfterOrderSave();
          showSuccess(description: 'KOT sent — continue adding items');
          return;
        }

        clearOrderDraft();

        if (isHoldOnly) {
          showSuccess(description: loc.order_saved);
          await _returnAfterOrderSave();
          return;
        }

        if (!isBilling) {
          showSuccess(description: loc.order_saved);
          await _returnAfterOrderSave();
          return;
        }

        showSuccess(description: loc.order_saved);
        await _refreshTablesAfterOrderSave();

        await Modular.to.pushNamed(
          HomeMainRoutes.invoiceScreen,
          arguments: {
            'invoice': request,
            'orderFrom': selectedOrderSource.value,
            'isEdit': isEdit.value,
            'isOffline': false,
          },
        );
      } else {
        showError(description: loc.order_failed);
      }
    } else {
      try {
        final tempOrderId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        final orderModel = _mapToOrderModel(
          request,
          tempOrderId,
          statusOverride: localStatusForUi,
        );

        await db.insertOrders(
          [orderModel],
          appPref.selectedOutlet!.id!,
          isSyncedFromApi: false,
        );

        if (await NetworkUtils.hasInternetConnection()) {
          unawaited(SyncManager().triggerSync(immediate: true));
        }

        await homeController.getOrderList(forceApiRefresh: true);
        if (Get.isRegistered<BusinessOverviewController>()) {
          await Get.find<BusinessOverviewController>().getOrderList(
            forceApiRefresh: true,
          );
        }

        await _syncTableStatusForDineInOrder(
          orderStatus: normalizedStatus,
          tableNumber: request.tableNumber,
          currentBillNumber: request.billNumber,
        );

        final loc = AppLocalizations.of(Get.context!)!;
        if (sendToKitchen || shouldPrintKot) {
          if (shouldPrintKot) {
            await _maybeAutoPrintKOT(
              request,
              orderId: tempOrderId,
              kotItemsOverride: kotDeltaForPrint,
            );
          }
          await _commitKotPrintedBaseline(orderId: tempOrderId);
        }

        if (stayOnScreen) {
          orderDetails['id'] = tempOrderId;
          orderDetails['billNumber'] = request.billNumber;
          await _enterEditModeAfterSave(
            responseData: {'id': tempOrderId, 'billNumber': request.billNumber},
            request: request,
          );
          await _refreshTablesAfterOrderSave();
          showSuccess(
            description: 'KOT sent (offline) — continue adding items',
          );
          return;
        }

        clearOrderDraft();

        if (isHoldOnly || !isBilling) {
          showSuccess(description: loc.order_saved_offline);
          await _returnAfterOrderSave();
          return;
        }

        showSuccess(description: loc.order_saved_offline);

        await Modular.to.pushNamed(
          HomeMainRoutes.invoiceScreen,
          arguments: {
            'invoice': request,
            'orderFrom': selectedOrderSource.value,
            'isEdit': isEdit.value,
            'isOffline': true,
          },
        );
      } catch (e) {
        debugPrint('Offline order save failed: $e');
        showError(
          description: '${loc.failed_to_save_order_offline} (${e.toString()})',
        );
      }
    }
  }

  Future<String> _generateNextIntegerBillNumber() async {
    try {
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return "1";

      int outletBillNumber = 0;
      try {
        final userResponse = await callApi(
          apiClient.getUserDetails(appPref.user!.id!),
          showLoader: false,
        );

        if (userResponse != null && userResponse.status == 'success') {
          appPref.user = userResponse.data;

          final selectedOutlet = userResponse.data.outletData?.firstWhere(
            (outlet) => outlet.id == outletId,
            orElse: () => userResponse.data.outletData?.first ?? OutletData(),
          );

          outletBillNumber = selectedOutlet?.billNumber ?? 0;
          debugPrint('📌 Outlet billNumber from API: $outletBillNumber');
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch user details: $e');
        outletBillNumber = appPref.selectedOutlet?.billNumber ?? 0;
        debugPrint(
          '📌 Using outlet billNumber from appPref: $outletBillNumber',
        );
      }

      final localOrders = await db.getAllOrders(outletId: outletId);

      List<api.OrderModel> apiOrders = [];
      final isOnline = await NetworkUtils.hasInternetConnection();
      if (isOnline) {
        try {
          final response = await callApi(
            apiClient.getOrders(
              appPref.user!.id!,
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
            apiOrders = response!.data;
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch API orders for bill number: $e');
        }
      }

      int maxOrderBillNumber = 0;

      for (final order in localOrders) {
        final billNum = int.tryParse(order.billNumber);
        if (billNum != null && billNum > maxOrderBillNumber) {
          maxOrderBillNumber = billNum;
        }
      }

      for (final order in apiOrders) {
        final billNum = int.tryParse(order.billNumber);
        if (billNum != null && billNum > maxOrderBillNumber) {
          maxOrderBillNumber = billNum;
        }
      }

      final baseBillNumber = outletBillNumber > maxOrderBillNumber
          ? outletBillNumber
          : maxOrderBillNumber;

      // Generate the next integer bill number.
      final finalBillNumber = baseBillNumber == 0 ? 1 : (baseBillNumber + 1);

      debugPrint('📊 Bill number calculation:');
      debugPrint('   Outlet billNumber: $outletBillNumber');
      debugPrint('   Max order billNumber: $maxOrderBillNumber');
      debugPrint('   Base billNumber: $baseBillNumber');
      debugPrint('   Final billNumber: $finalBillNumber');

      return finalBillNumber.toString();
    } catch (e) {
      debugPrint('❌ Error generating bill number: $e');
      return "1";
    }
  }

  Future<bool> _isBillNumberUnique(
    String billNumber, {
    String? excludeOrderId,
  }) async {
    try {
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return true;

      final localOrders = await db.getAllOrders(outletId: outletId);
      final existsInLocal = localOrders.any((order) {
        if (excludeOrderId != null && order.id == excludeOrderId) return false;
        return order.billNumber.toLowerCase() == billNumber.toLowerCase();
      });

      if (existsInLocal) {
        debugPrint('⚠️ Bill number $billNumber exists in local database');
        return false;
      }

      final isOnline = await NetworkUtils.hasInternetConnection();
      if (isOnline) {
        try {
          final response = await callApi(
            apiClient.getOrders(
              appPref.user!.id!,
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
            final existsInApi = response!.data.any((order) {
              if (excludeOrderId != null && order.id == excludeOrderId)
                return false;
              return order.billNumber.toLowerCase() == billNumber.toLowerCase();
            });
            if (existsInApi) {
              debugPrint('⚠️ Bill number $billNumber exists in API');
              return false;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Could not check API for bill number: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error checking bill number uniqueness: $e');
      return true;
    }
  }

  api.OrderModel _mapToOrderModel(
    CreateorderRequest r,
    String id, {
    String? statusOverride,
  }) {
    return api.OrderModel(
      outletId: r.outletId ?? appPref.selectedOutlet!.id!,
      id: id,
      billNumber: r.billNumber ?? '',
      userId: r.userId ?? appPref.user!.id ?? '',
      tableNumber: r.tableNumber,
      customerName: r.customerName,
      phoneNumber: r.phoneNumber,
      subtotal: r.subtotal ?? 0,
      totalTax: r.totalTax ?? 0,
      discount: r.discount ?? 0,
      serviceCharge: r.serviceCharge ?? 0,
      totalAmount: r.totalAmount ?? 0,
      paymentReceivedIn: r.paymentReceivedIn,
      splitPayments: r.splitPayments,
      status: (statusOverride ?? r.status ?? 'pending'),
      orderFrom: r.orderFrom ?? selectedOrderSource.value,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      items: (r.items ?? []).map((oi) {
        return api.OrderItem(
          itemId: oi.itemId,
          itemName: oi.itemName,
          category: oi.category,
          quantity: oi.quantity,
          salePrice: oi.salePrice,
          gst: oi.gst,
          kotSentQuantity: oi.kotSentQuantity,
          itemRemark: oi.itemRemark,
        );
      }).toList(),
    );
  }

  // --------------------
  // Totals calculation
  // --------------------
  Future<void> calculateTotals() async {
    double s = 0.0;
    double t = 0.0;

    for (final entry in itemQuantities.entries) {
      final id = entry.key;
      final qty = entry.value;
      // Use allItemsMap for lookup instead of items list to find items across all categories
      final itm = allItemsMap[id];
      if (itm == null) continue;

      final double price = double.tryParse(itm.salePrice.toString()) ?? 0.0;
      final bool withTax = (itm.withTax ?? false);
      final double gstRate =
          double.tryParse((itm.gst ?? 0.0).toString()) ?? 0.0;

      final double lineSubtotal = price * qty;
      final double lineTax = withTax ? (lineSubtotal * gstRate / 100.0) : 0.0;

      s += lineSubtotal;
      t += lineTax;
    }

    subtotal.value = s;
    totalTax.value = t;

    final discount = (orderDetails['discount'] is num)
        ? (orderDetails['discount'] as num).toDouble()
        : (double.tryParse('${orderDetails['discount'] ?? 0}') ?? 0.0);
    final serviceCharge = (orderDetails['serviceCharge'] is num)
        ? (orderDetails['serviceCharge'] as num).toDouble()
        : (double.tryParse('${orderDetails['serviceCharge'] ?? 0}') ?? 0.0);

    totalAmount.value = s + t + serviceCharge - discount;
    debugPrint(
      'Totals updated -> subtotal: ${subtotal.value}, tax: ${totalTax.value}, total: ${totalAmount.value}',
    );
  }

  // --------------------
  // Helpers
  // --------------------
  String _generateBillNumber() {
    final dt = DateTime.now();
    return 'BILL-${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}-${dt.microsecondsSinceEpoch % 100000}';
  }

  bool _isDineInOrder() =>
      selectedOrderSource.value.trim().toLowerCase() == 'dine in';

  /// Table is mandatory for Dine In when outlet uses table management.
  bool _requiresDineInTable() =>
      _isDineInOrder() && HomeMainRoutes.outletShowsTables();

  String _normalizeTableNumber(String value) {
    var normalized = value.trim().toLowerCase();
    normalized = normalized.replaceFirst(RegExp(r'^table\s*'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    return normalized;
  }

  Future<bool> _hasAnotherActiveOrderOnTable(String tableNumber) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return false;

    final currentOrderId = orderDetails['id']?.toString();
    final targetTable = _normalizeTableNumber(tableNumber);
    if (targetTable.isEmpty) return false;

    try {
      final allOrders = await db.getAllOrders(outletId: outletId);
      final hasLocalConflict = allOrders.any((order) {
        final status = order.status.trim().toLowerCase();
        if (status == 'closed') return false;
        if (currentOrderId != null && order.id == currentOrderId) return false;

        final orderTable = _normalizeTableNumber(order.tableNumber ?? '');
        return orderTable.isNotEmpty && orderTable == targetTable;
      });
      if (hasLocalConflict) return true;

      final isOnline = await NetworkUtils.hasInternetConnection();
      if (!isOnline) return false;

      final response = await callApi(
        apiClient.getOrders(
          appPref.user!.id!,
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
      if (response?.status != 'success') return false;

      return response!.data.any((order) {
        final status = order.status.trim().toLowerCase();
        if (status == 'closed') return false;
        if (currentOrderId != null && order.id == currentOrderId) return false;

        final orderTable = _normalizeTableNumber(order.tableNumber ?? '');
        return orderTable.isNotEmpty && orderTable == targetTable;
      });
    } catch (_) {
      return false;
    }
  }

  Future<void> _returnAfterOrderSave() async {
    await _refreshTablesAfterOrderSave();
    if (isFromTableScreen.value) {
      Modular.to.navigate(HomeMainRoutes.tables);
      return;
    }
    if (Modular.to.canPop()) {
      Modular.to.pop();
    }
  }

  Future<void> _refreshTablesAfterOrderSave() async {
    if (Get.isRegistered<TableController>()) {
      await Get.find<TableController>().refresh();
    }
  }

  Future<void> _syncTableStatusForDineInOrder({
    required String orderStatus,
    required String? tableNumber,
    String? currentBillNumber,
  }) async {
    if (!_isDineInOrder()) return;
    final rawTable = (tableNumber ?? '').trim();
    if (rawTable.isEmpty) return;

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    try {
      final tablesResponse = await callApi(
        apiClient.getOutletTables(outletId),
        showLoader: false,
      );
      if (tablesResponse?.status != 'success') return;

      final normalizedTarget = _normalizeTableNumber(rawTable);
      TableData? table;
      for (final t in tablesResponse!.data) {
        final keys = {
          _normalizeTableNumber(t.tableNumber),
          _normalizeTableNumber('Table ${t.tableNumber}'),
        };
        if (t.tableNumber.toLowerCase().startsWith('table ')) {
          keys.add(_normalizeTableNumber(t.tableNumber));
        }
        keys.removeWhere((e) => e.isEmpty);
        if (keys.contains(normalizedTarget)) {
          table = t;
          break;
        }
      }
      if (table == null) {
        debugPrint('⚠️ Table not found for sync: $rawTable');
        return;
      }

      final normalizedStatus = orderStatus.trim().toLowerCase();
      final nextStatus = switch (normalizedStatus) {
        'closed' => 'available',
        'billing' => 'billing',
        _ => 'occupied',
      };

      await callApi(
        apiClient.updateTableStatus(table.id, {
          'status': nextStatus,
          'currentBillNumber': nextStatus == 'available'
              ? null
              : currentBillNumber,
        }),
        showLoader: false,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to sync table status: $e');
    }
  }

  void openSettings() async {
    // await Get.toNamed(AppRoute.orderPreferences);
    await Modular.to.pushNamed(HomeMainRoutes.orderSettings);

    // Sync from preferences when returning
    isListView.value = appPref.isListView;
    isKOT.value = appPref.isKOT;
    showAddDetailsOnCreateOrder.value = appPref.showAddDetailsOnCreateOrder;
    // Force Obx to rebuild even if value didn't change (same view re-selected)
    isListView.refresh();
    isKOT.refresh();
    showAddDetailsOnCreateOrder.refresh();
  }

  @override
  void onClose() {
    itemNameController.dispose();
    salePriceController.dispose();
    remarkController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }
}
