import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/Database/app_database.dart' as dbs;
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
import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/services/ai/menu_ai_scanner.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/utils/date_util.dart';
import 'dart:async';
import 'dart:io';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Invoice/invoice_controller.dart';

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
  final RxInt itemsPerPage = 10.obs;
  final RxBool hasMoreItems = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryId = 'none'.obs;

  // State
  final RxMap<String, int> itemQuantities = <String, int>{}.obs;
  final RxString selectedTaxOption = 'Without Tax'.obs;
  final RxString selectedGSTRate = 'None'.obs;
  final RxString selectedOrderSource = ''.obs;

  final RxList<ItemData> items = <ItemData>[].obs;
  final RxList<CategoryData> categories = <CategoryData>[].obs;

  // Map to store all items for lookup (persists across category changes)
  final RxMap<String, ItemData> allItemsMap = <String, ItemData>{}.obs;

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

  void setOrderDetails(Map<String, dynamic> details) {
    orderDetails = details;
    orderDetailsVersion.value++;
    calculateTotals();
  }

  void clearOrderDraft() {
    itemQuantities.clear();
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
          !isEdit.value &&
          (args['tableNumber']?.toString().trim().isNotEmpty ?? false);

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

    if (isEdit.value && orders != null) {
      _loadOrderForEdit();
    } else {
      // Only show dialog if order source is not already set (e.g., from table screen).
      // Cafe / restaurant: user picks channel; other outlets: default without blocking.
      if (selectedOrderSource.value.isEmpty) {
        if (HomeMainRoutes.outletIsCafeOrRestaurant()) {
          _showOrderSourceDialog();
        } else {
          selectedOrderSource.value = 'Takeaway';
        }
      }
    }
  }

  void _loadOrderForEdit() {
    itemQuantities.clear();

    for (final item in orders!.items) {
      itemQuantities[item.itemId] = item.quantity ?? 1;
    }

    calculateTotals();
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
    } else {
      itemQuantities[itemId] = current - 1;
    }
    calculateTotals();
  }

  void removeItemCompletely(String itemId) {
    itemQuantities.remove(itemId);
    calculateTotals();
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

  /// Opens a simple confirmation prompt before placing the order.
  void showConfirmOrderBottomSheet(String status) {
    final context = Get.context!;
    final loc = AppLocalizations.of(context)!;
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
    final isBilling = status == 'closed';
    final actionLabel = isBilling
        ? (isKotFeatureActive ? 'KOT & Bill' : loc.save_and_bill)
        : (isKotFeatureActive ? loc.kot_and_hold : loc.save_and_hold);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text('Are you sure you want to $actionLabel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              saveAndBill(status);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
      final response = await callApi(
        apiClient.getCategories(appPref.selectedOutlet!.id!),
      );
      if (response != null && response.status == 'success') {
        categories.value = response.categories ?? [];
        dismissAllAppLoader();
      } else {
        debugPrint('getCategories: unexpected response: $response');
      }
    } catch (e, st) {
      debugPrint('getCategories error: $e\n$st');
    }
  }

  // KOT Bill //

  final TextEditingController remarkController = TextEditingController();

  Future<void> showRemarkDialog() async {
    remarkController.clear();
    await Get.dialog(
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
                'Add Remark',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter remark for this order',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Get.back(result: remarkController.text.trim());
                },
                child: Text(AppLocalizations.of(Get.context!)!.save_remark),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
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

    final List<OrderItem> kotItems = [];

    for (final entry in itemQuantities.entries) {
      final itemId = entry.key;
      final qty = entry.value;

      if (qty < 1) continue;

      final item = allItemsMap[itemId];
      if (item == null) continue;

      kotItems.add(
        OrderItem(
          itemId: item.id,
          itemName: item.itemName,
          category: item.category,
          quantity: qty,
          salePrice: item.salePrice,
          gst: item.gst?.toDouble() ?? 0.0,
        ),
      );
    }

    String kotBillNumber = orderDetails['billNumber']?.toString() ?? '';
    if (kotBillNumber.isEmpty) {
      kotBillNumber = await _generateNextIntegerBillNumber();
    }

    final kotRequest = CreateorderRequest(
      billNumber: kotBillNumber,
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
      },
    );
  }

  Future<void> _maybeAutoPrintKOT(CreateorderRequest request) async {
    if (!isKotFeatureActive) return;

    try {
      final printerService = ThermalPrinterService.instance;
      // Route KOT to the KOT printer (if configured), otherwise user will be
      // prompted to connect and it will be saved as KOT printer automatically.
      final connected = await printerService.ensureConnectedForRole(
        PrintRole.kot,
      );
      if (!connected) return;

      final now = DateTime.now().toString();
      final dateStr = formatDate(now);
      final timeStr = formatTime(now);

      final kotItems = (request.items ?? const <OrderItem>[])
          .where((i) => i.quantity > 0)
          .toList(growable: false);

      final totalQty = kotItems.fold<int>(0, (sum, i) => sum + i.quantity);

      await printerService.printKOT(
        kotNumber: request.billNumber ?? '',
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

      payload.add(
        OrderItem(
          itemId: item.id,
          itemName: item.itemName,
          category: item.category,
          quantity: e.value,
          salePrice: item.salePrice,
          gst: item.gst.toDouble(),
        ),
      );
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
      discount: (orderDetails['discount'] ?? 0).toDouble(),
      serviceCharge: (orderDetails['serviceCharge'] ?? 0).toDouble(),
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

  Future<void> saveAndBill(String status) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final normalizedStatus = status.trim().toLowerCase();
    // API expects 'pending' for billing flow, but the app UI/table status relies on
    // local order status. So keep a separate local status for correct table state.
    final localStatusForUi = normalizedStatus;
    final orderStatusForApi = normalizedStatus == 'billing'
        ? 'pending'
        : normalizedStatus;
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

      final hasConflict = await _hasAnotherActiveOrderOnTable(tableNumber);
      if (hasConflict) {
        showError(description: 'This table already has an active order');
        return;
      }
    }

    final List<OrderItem> payload = [];

    for (final e in itemQuantities.entries) {
      final item = allItemsMap[e.key];
      if (item == null) continue;

      payload.add(
        OrderItem(
          itemId: item.id,
          itemName: item.itemName,
          category: item.category,
          quantity: e.value,
          salePrice: item.salePrice,
          gst: item.gst.toDouble(),
        ),
      );
    }

    String? finalBillNumber;
    if (isEdit.value) {
      finalBillNumber = orderDetails['billNumber'];
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
      discount: (orderDetails['discount'] ?? 0).toDouble(),
      serviceCharge: (orderDetails['serviceCharge'] ?? 0).toDouble(),
      paymentReceivedIn: orderDetails['paymentReceivedIn'],
      splitPayments: splitPaymentsList,
      status: orderStatusForApi,
      orderFrom: selectedOrderSource.value,
      subtotal: subtotal.value,
      totalTax: totalTax.value,
      totalAmount: totalAmount.value,
      items: payload,
    );

    final hasInternet = await NetworkUtils.hasInternetConnection();

    if (hasInternet) {
      final response = isEdit.value
          ? await callApi(
              apiClient.updateOrder(orderDetails['id'], request.toJson()),
            )
          : await callApi(apiClient.addOrder(request.toJson()));

      if (response != null && response['status'] == 'success') {
        final orderModel = _mapToOrderModel(
          request,
          response['data']?['id'] ?? orderDetails['id'],
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
        );

        await homeController.getOrderList(forceApiRefresh: true);
        if (Get.isRegistered<BusinessOverviewController>()) {
          await Get.find<BusinessOverviewController>().getOrderList(
            forceApiRefresh: true,
          );
        }

        final loc = AppLocalizations.of(Get.context!)!;
        showSuccess(description: loc.order_saved);

        await _maybeAutoPrintKOT(request);

        // Clear local draft state before showing invoice preview.
        clearOrderDraft();

        await Modular.to.pushNamed(
          HomeMainRoutes.invoiceScreen,
          arguments: {
            'invoice': request,
            'orderFrom': selectedOrderSource.value,
            'isEdit': isEdit.value,
            'isOffline': false,
          },
        );
        // await Get.toNamed(
        //   AppRoute.pdfPreview,
        //   arguments: {
        //     'invoice': request,
        //     'orderFrom': selectedOrderSource.value,
        //     'isEdit': isEdit.value,
        //     'isOffline': false,
        //   },
        // );
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

        await homeController.getOrderList(forceApiRefresh: true);
        if (Get.isRegistered<BusinessOverviewController>()) {
          await Get.find<BusinessOverviewController>().getOrderList(
            forceApiRefresh: true,
          );
        }

        final loc = AppLocalizations.of(Get.context!)!;
        showSuccess(description: loc.order_saved_offline);

        await _maybeAutoPrintKOT(request);

        // Clear local draft state before showing invoice preview.
        clearOrderDraft();

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
        showError(description: loc.failed_to_save_order_offline);
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

      // If bill number is 0, set it to 1
      final finalBillNumber = baseBillNumber == 0 ? 1 : baseBillNumber;

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
      outletId: r.outletId!,
      id: id,
      billNumber: r.billNumber!,
      userId: r.userId!,
      tableNumber: r.tableNumber,
      customerName: r.customerName,
      phoneNumber: r.phoneNumber,
      subtotal: r.subtotal!,
      totalTax: r.totalTax!,
      discount: r.discount!,
      serviceCharge: r.serviceCharge!,
      totalAmount: r.totalAmount!,
      paymentReceivedIn: r.paymentReceivedIn,
      splitPayments: r.splitPayments,
      status: (statusOverride ?? r.status!),
      orderFrom: r.orderFrom!,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      items: r.items!.map((oi) {
        return api.OrderItem(
          itemId: oi.itemId,
          itemName: oi.itemName,
          category: oi.category,
          quantity: oi.quantity,
          salePrice: oi.salePrice,
          gst: oi.gst,
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

  /// Table is mandatory for Dine In only when the Add Details flow is available.
  bool _requiresDineInTable() =>
      _isDineInOrder() && appPref.showAddDetailsOnCreateOrder;

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
      return allOrders.any((order) {
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

  Future<void> _syncTableStatusForDineInOrder({
    required String orderStatus,
    required String? tableNumber,
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
      final table = tablesResponse!.data.firstWhereOrNull((t) {
        final rawKey = _normalizeTableNumber(t.tableNumber);
        final displayKey = _normalizeTableNumber('Table ${t.tableNumber}');
        return rawKey == normalizedTarget || displayKey == normalizedTarget;
      });
      if (table == null) return;

      final normalizedStatus = orderStatus.trim().toLowerCase();
      final nextStatus = switch (normalizedStatus) {
        'closed' => 'available',
        'billing' => 'billing',
        _ => 'occupied',
      };

      await callApi(
        apiClient.updateTableStatus(table.id, {'status': nextStatus}),
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
    _searchDebounce?.cancel();
    super.onClose();
  }
}
