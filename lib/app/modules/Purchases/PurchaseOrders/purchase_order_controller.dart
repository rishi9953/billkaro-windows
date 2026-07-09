import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_drawer_scope.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

class PurchaseOrderController extends BaseController {
  late final InventoryController inventory;

  final purchaseOrders = <PurchaseOrderData>[].obs;
  final tabIds = <int>[1].obs;
  final activeTabIndex = 0.obs;
  int _nextTabId = 2;

  static const accent = Color(0xFFEF8819);
  static const cardBg = Colors.white;
  static const screenBg = Color(0xFFF0F4FA);
  static const drawerTopInset = 40.0;

  String get outletId => appPref.selectedOutlet?.id ?? '';
  String get userId => appPref.user?.id ?? '';

  List<SupplierData> get suppliers => inventory.suppliers;

  @override
  void onInit() {
    super.onInit();
    inventory = Get.isRegistered<InventoryController>()
        ? Get.find<InventoryController>()
        : Get.put(InventoryController());
    loadPurchaseOrders();
    _syncDrawerTab();
  }

  String get currentTabId => 'purchase-tab-${tabIds[activeTabIndex.value]}';

  Future<void> loadPurchaseOrders() async {
    final res = await callApi(
      apiClient.getPurchaseOrders(outletId, null),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      purchaseOrders.value = (res['data'] as List)
          .map((e) => PurchaseOrderData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<bool> receivePurchaseOrder(String poId) async {
    final res = await callApi(
      apiClient.receivePurchaseOrder(outletId, poId, {'userId': userId}),
    );
    if (res != null) {
      await loadPurchaseOrders();
      await inventory.loadRawMaterials();
      await inventory.loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    String? notes,
    DateTime? expectedDate,
    String? paymentTerms,
    String? referenceNo,
    String? documentType,
    String? billingName,
    String? billingAddressLine1,
    String? billingAddressLine2,
    String? billingPinCode,
    String? billingState,
    String? billingContact,
    String? billingGstNo,
    String? shippingName,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingPinCode,
    String? shippingState,
    String? shippingContact,
    String? shippingGstNo,
    String? termsAndConditions,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      'outletId': outletId,
      'supplierId': supplierId,
      'items': items,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (expectedDate != null)
        'expectedDate': expectedDate.toUtc().toIso8601String(),
      if (paymentTerms != null && paymentTerms.isNotEmpty)
        'paymentTerms': paymentTerms,
      if (referenceNo != null && referenceNo.isNotEmpty)
        'referenceNo': referenceNo,
      if (documentType != null && documentType.isNotEmpty)
        'documentType': documentType,
      if (billingName != null && billingName.isNotEmpty)
        'billingName': billingName,
      if (billingAddressLine1 != null && billingAddressLine1.isNotEmpty)
        'billingAddressLine1': billingAddressLine1,
      if (billingAddressLine2 != null && billingAddressLine2.isNotEmpty)
        'billingAddressLine2': billingAddressLine2,
      if (billingPinCode != null && billingPinCode.isNotEmpty)
        'billingPinCode': billingPinCode,
      if (billingState != null && billingState.isNotEmpty)
        'billingState': billingState,
      if (billingContact != null && billingContact.isNotEmpty)
        'billingContact': billingContact,
      if (billingGstNo != null && billingGstNo.isNotEmpty)
        'billingGstNo': billingGstNo,
      if (shippingName != null && shippingName.isNotEmpty)
        'shippingName': shippingName,
      if (shippingAddressLine1 != null && shippingAddressLine1.isNotEmpty)
        'shippingAddressLine1': shippingAddressLine1,
      if (shippingAddressLine2 != null && shippingAddressLine2.isNotEmpty)
        'shippingAddressLine2': shippingAddressLine2,
      if (shippingPinCode != null && shippingPinCode.isNotEmpty)
        'shippingPinCode': shippingPinCode,
      if (shippingState != null && shippingState.isNotEmpty)
        'shippingState': shippingState,
      if (shippingContact != null && shippingContact.isNotEmpty)
        'shippingContact': shippingContact,
      if (shippingGstNo != null && shippingGstNo.isNotEmpty)
        'shippingGstNo': shippingGstNo,
      if (termsAndConditions != null && termsAndConditions.isNotEmpty)
        'termsAndConditions': termsAndConditions,
      'currency': 'INR',
    };
    final res = await callApi(apiClient.createPurchaseOrder(outletId, body));
    if (res != null) {
      await loadPurchaseOrders();
      await inventory.loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> updatePurchaseOrder({
    required String poId,
    required String supplierId,
    required List<Map<String, dynamic>> items,
    String? notes,
    DateTime? expectedDate,
    String? paymentTerms,
    String? referenceNo,
    String? documentType,
    String? billingName,
    String? billingAddressLine1,
    String? billingAddressLine2,
    String? billingPinCode,
    String? billingState,
    String? billingContact,
    String? billingGstNo,
    String? shippingName,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingPinCode,
    String? shippingState,
    String? shippingContact,
    String? shippingGstNo,
    String? termsAndConditions,
  }) async {
    final body = <String, dynamic>{
      'supplierId': supplierId,
      'items': items,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (expectedDate != null)
        'expectedDate': expectedDate.toUtc().toIso8601String(),
      if (paymentTerms != null && paymentTerms.isNotEmpty)
        'paymentTerms': paymentTerms,
      if (referenceNo != null && referenceNo.isNotEmpty)
        'referenceNo': referenceNo,
      if (documentType != null && documentType.isNotEmpty)
        'documentType': documentType,
      if (billingName != null && billingName.isNotEmpty)
        'billingName': billingName,
      if (billingAddressLine1 != null && billingAddressLine1.isNotEmpty)
        'billingAddressLine1': billingAddressLine1,
      if (billingAddressLine2 != null && billingAddressLine2.isNotEmpty)
        'billingAddressLine2': billingAddressLine2,
      if (billingPinCode != null && billingPinCode.isNotEmpty)
        'billingPinCode': billingPinCode,
      if (billingState != null && billingState.isNotEmpty)
        'billingState': billingState,
      if (billingContact != null && billingContact.isNotEmpty)
        'billingContact': billingContact,
      if (billingGstNo != null && billingGstNo.isNotEmpty)
        'billingGstNo': billingGstNo,
      if (shippingName != null && shippingName.isNotEmpty)
        'shippingName': shippingName,
      if (shippingAddressLine1 != null && shippingAddressLine1.isNotEmpty)
        'shippingAddressLine1': shippingAddressLine1,
      if (shippingAddressLine2 != null && shippingAddressLine2.isNotEmpty)
        'shippingAddressLine2': shippingAddressLine2,
      if (shippingPinCode != null && shippingPinCode.isNotEmpty)
        'shippingPinCode': shippingPinCode,
      if (shippingState != null && shippingState.isNotEmpty)
        'shippingState': shippingState,
      if (shippingContact != null && shippingContact.isNotEmpty)
        'shippingContact': shippingContact,
      if (shippingGstNo != null && shippingGstNo.isNotEmpty)
        'shippingGstNo': shippingGstNo,
      if (termsAndConditions != null && termsAndConditions.isNotEmpty)
        'termsAndConditions': termsAndConditions,
      'currency': 'INR',
    };
    final res = await callApi(
      apiClient.updatePurchaseOrder(outletId, poId, body),
    );
    if (res != null) {
      await loadPurchaseOrders();
      await inventory.loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> cancelPurchaseOrder(String poId) async {
    final res = await callApi(apiClient.cancelPurchaseOrder(outletId, poId));
    if (res != null) {
      await loadPurchaseOrders();
      await inventory.loadDashboard();
      return true;
    }
    return false;
  }

  List<PoLineSuggestion> suggestedPoLines({String? supplierId}) {
    return inventory.rawMaterials.where((m) {
      if (!m.isActive || !m.isLowStock) return false;
      if (supplierId != null && supplierId.isNotEmpty) {
        final linked = m.supplierId;
        if (linked != null && linked.isNotEmpty && linked != supplierId) {
          return false;
        }
      }
      return true;
    }).map((m) {
      final deficit = m.minStock - m.currentStock;
      final qty = deficit > 0 ? deficit : m.minStock;
      return PoLineSuggestion(
        rawMaterialId: m.id,
        quantity: qty < 0.001 ? m.minStock : qty,
        unitPrice: m.purchasePrice,
      );
    }).toList();
  }

  void addTab() {
    tabIds.add(_nextTabId++);
    activeTabIndex.value = tabIds.length - 1;
    _syncDrawerTab();
  }

  void selectTab(int index) {
    if (index < 0 || index >= tabIds.length) return;
    activeTabIndex.value = index;
    _syncDrawerTab();
  }

  void closeTab(int index) {
    if (index < 0 || index >= tabIds.length) return;

    final closingTabId = 'purchase-tab-${tabIds[index]}';
    if (isPoDrawerOwnedByTab(closingTabId)) {
      closeActivePoDrawer();
    }

    tabIds.removeAt(index);
    if (activeTabIndex.value >= tabIds.length) {
      activeTabIndex.value = tabIds.length - 1;
    } else if (activeTabIndex.value > index) {
      activeTabIndex.value--;
    }
    _syncDrawerTab();
  }

  Future<bool> cancelOrder(String id) => cancelPurchaseOrder(id);

  Future<bool> receiveOrder(String id) => receivePurchaseOrder(id);

  void confirmDelete(
    String name,
    Future<bool> Function() onConfirm,
    AppLocalizations loc,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(loc.confirm_delete),
        content: Text(loc.delete_confirm_message(name)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await onConfirm();
              Get.back();
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  String formatAmount(num value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);

  String formatDate(String iso) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  void _syncDrawerTab() => setVisiblePoDrawerTab(currentTabId);
}
