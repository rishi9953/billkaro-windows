import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';

class InventoryController extends BaseController {
  final isLoading = false.obs;
  final selectedTab = 0.obs;
  final searchQuery = ''.obs;
  final showLowStockOnly = false.obs;

  final dashboard = Rxn<InventoryDashboardData>();
  final rawMaterials = <RawMaterialData>[].obs;
  final suppliers = <SupplierData>[].obs;
  final transactions = <StockTransactionData>[].obs;
  final purchaseOrders = <PurchaseOrderData>[].obs;
  final recipes = <RecipeData>[].obs;

  String get outletId => appPref.selectedOutlet?.id ?? '';
  String get userId => appPref.user?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadDashboard(),
        loadRawMaterials(),
        loadSuppliers(),
        loadTransactions(),
        loadPurchaseOrders(),
        loadRecipes(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDashboard() async {
    final res = await callApi(
      apiClient.getInventoryDashboard(outletId),
      showLoader: false,
    );
    if (res is Map && res['data'] != null) {
      dashboard.value = InventoryDashboardData.fromJson(
        Map<String, dynamic>.from(res['data'] as Map),
      );
    }
  }

  Future<void> loadRawMaterials() async {
    final res = await callApi(
      apiClient.getRawMaterials(
        outletId,
        searchQuery.value.isEmpty ? null : searchQuery.value,
        null,
        showLowStockOnly.value ? true : null,
      ),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      rawMaterials.value = (res['data'] as List)
          .map((e) => RawMaterialData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> loadSuppliers() async {
    final res = await callApi(
      apiClient.getSuppliers(outletId, null),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      suppliers.value = (res['data'] as List)
          .map((e) => SupplierData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> loadTransactions() async {
    final res = await callApi(
      apiClient.getStockTransactions(outletId, null, null, 1, 50),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      transactions.value = (res['data'] as List)
          .map((e) => StockTransactionData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

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

  Future<void> loadRecipes() async {
    final res = await callApi(
      apiClient.getRecipes(outletId, null),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      recipes.value = (res['data'] as List)
          .map((e) => RecipeData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<bool> createRawMaterial(Map<String, dynamic> body) async {
    final res = await callApi(
      apiClient.createRawMaterial(outletId, {
        ...body,
        'userId': userId,
        'outletId': outletId,
      }),
    );
    if (res != null) {
      await loadRawMaterials();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> deleteRawMaterial(String id) async {
    final res = await callApi(apiClient.deleteRawMaterial(outletId, id));
    if (res != null) {
      await loadRawMaterials();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> createSupplier(Map<String, dynamic> body) async {
    final res = await callApi(
      apiClient.createSupplier(outletId, {
        ...body,
        'userId': userId,
        'outletId': outletId,
      }),
    );
    if (res != null) {
      await loadSuppliers();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> adjustStock({
    required String rawMaterialId,
    required String type,
    required double quantity,
    String? notes,
  }) async {
    final res = await callApi(
      apiClient.createStockTransaction(outletId, {
        'userId': userId,
        'outletId': outletId,
        'rawMaterialId': rawMaterialId,
        'type': type,
        'quantity': quantity,
        'notes': notes,
      }),
    );
    if (res != null) {
      await loadRawMaterials();
      await loadTransactions();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> receivePurchaseOrder(String poId) async {
    final res = await callApi(
      apiClient.receivePurchaseOrder(outletId, poId, {'userId': userId}),
    );
    if (res != null) {
      await loadPurchaseOrders();
      await loadRawMaterials();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> createRecipe({
    required String itemId,
    required String rawMaterialId,
    required double quantity,
  }) async {
    final res = await callApi(
      apiClient.createRecipe(outletId, {
        'userId': userId,
        'outletId': outletId,
        'itemId': itemId,
        'rawMaterialId': rawMaterialId,
        'quantity': quantity,
      }),
    );
    if (res != null) {
      await loadRecipes();
      return true;
    }
    return false;
  }

  Future<bool> deleteRecipe(String id) async {
    final res = await callApi(apiClient.deleteRecipe(outletId, id));
    if (res != null) {
      await loadRecipes();
      return true;
    }
    return false;
  }

  String materialName(String id) {
    return rawMaterials
            .firstWhereOrNull((m) => m.id == id)
            ?.name ??
        id;
  }
}
