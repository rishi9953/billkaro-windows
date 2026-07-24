import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';

class InventoryController extends BaseController {
  final isLoading = false.obs;
  final selectedTab = 0.obs;
  final searchQuery = ''.obs;
  final supplierSearchQuery = ''.obs;
  final showLowStockOnly = false.obs;
  final recipeSearchQuery = ''.obs;

  final dashboard = Rxn<InventoryDashboardData>();
  final rawMaterials = <RawMaterialData>[].obs;
  final rawMaterialCategories = <String>[].obs;
  final suppliers = <SupplierData>[].obs;
  final transactions = <StockTransactionData>[].obs;
  final recipes = <RecipeData>[].obs;
  final menuItems = <ItemData>[].obs;
  final productStock = <ProductStockData>[].obs;
  final productStockSearch = ''.obs;
  final showProductLowStockOnly = false.obs;
  final categories = <CategoryData>[].obs;

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
        loadRawMaterialCategories(),
        loadSuppliers(),
        loadTransactions(),
        loadRecipes(),
        loadMenuItems(),
        loadProductStock(),
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

  Future<void> loadRawMaterialCategories() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;
    final loaded = await OfflineCategoryLoader.load(
      outletId: outletId,
      fetchFromApi: () =>
          callApi(apiClient.getCategories(outletId), showLoader: false),
    );
    categories.value = loaded;
    rawMaterialCategories.value = loaded
        .map((c) => c.categoryName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<void> loadSuppliers() async {
    final res = await callApi(
      apiClient.getSuppliers(
        outletId,
        supplierSearchQuery.value.isEmpty ? null : supplierSearchQuery.value,
      ),
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

  Future<void> loadRecipes({String? itemId}) async {
    final res = await callApi(
      apiClient.getRecipes(outletId, itemId),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      recipes.value = (res['data'] as List)
          .map((e) => RecipeData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> loadMenuItems() async {
    final res = await callApi(
      apiClient.getItems(outletId, 1, 500, null, null, null, null),
      showLoader: false,
    );
    if (res != null) {
      menuItems.value = res.data;
    }
  }

  Future<void> loadProductStock() async {
    final res = await callApi(
      apiClient.getProductStock(
        outletId,
        productStockSearch.value.isEmpty ? null : productStockSearch.value,
        true,
        showProductLowStockOnly.value ? true : null,
      ),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      productStock.value = (res['data'] as List)
          .map((e) => ProductStockData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<bool> adjustProductStock({
    required String itemId,
    required String adjustmentType,
    required double quantity,
    String reason = 'Other',
    String? notes,
  }) async {
    final res = await callApi(
      apiClient.adjustProductStock(outletId, itemId, {
        'userId': userId,
        'adjustmentType': adjustmentType,
        'quantity': quantity,
        'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    if (res is Map && res['status'] == 'success') {
      await Future.wait([loadProductStock(), loadDashboard()]);
      return true;
    }
    return false;
  }

  Future<List<ProductStockMovementData>> loadProductStockMovements({
    required String itemId,
    String? type,
  }) async {
    final res = await callApi(
      apiClient.getProductStockMovements(
        outletId,
        itemId,
        type == null || type == 'ALL' ? null : type,
      ),
      showLoader: false,
    );
    if (res is Map && res['data'] is Map) {
      final movements = res['data']['movements'];
      if (movements is List) {
        return movements
            .map(
              (e) => ProductStockMovementData.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    }
    return [];
  }

  /// Loads only data needed for recipe management (menu item screen, dialogs).
  Future<void> loadRecipeData() async {
    await Future.wait([
      loadRawMaterials(),
      loadMenuItems(),
      loadRecipes(),
    ]);
  }

  List<RecipeData> recipesForItem(String itemId) =>
      recipes.where((r) => r.itemId == itemId).toList();

  List<RecipeData> get filteredRecipes {
    final q = recipeSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return recipes;
    return recipes.where((r) {
      return r.itemName.toLowerCase().contains(q) ||
          r.rawMaterialName.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<RecipeData>> get recipesGroupedByItem {
    final map = <String, List<RecipeData>>{};
    for (final r in filteredRecipes) {
      map.putIfAbsent(r.itemId, () => []).add(r);
    }
    return map;
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

  Future<bool> updateRawMaterial(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await callApi(apiClient.updateRawMaterial(outletId, id, body));
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

  Future<bool> updateSupplier(String id, Map<String, dynamic> body) async {
    final res = await callApi(apiClient.updateSupplier(outletId, id, body));
    if (res != null) {
      await loadSuppliers();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> deleteSupplier(String id) async {
    final res = await callApi(apiClient.deleteSupplier(outletId, id));
    if (res != null) {
      await loadSuppliers();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> setSupplierActive(String id, bool isActive) async {
    return updateSupplier(id, {'isActive': isActive});
  }

  String generateVendorNo() {
    var max = 0;
    for (final s in suppliers) {
      final vendorNo = (s.vendorNo ?? '').trim();
      final match = RegExp(r'(\d+)\s*$').firstMatch(vendorNo);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    return 'VEN${(max + 1).toString().padLeft(4, '0')}';
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
      await loadDashboard();
      return true;
    }
    return false;
  }

  /// Creates multiple recipe lines for one menu item (e.g. sandwich ingredients).
  Future<bool> createRecipesBatch({
    required String itemId,
    required List<MapEntry<String, double>> ingredients,
  }) async {
    if (ingredients.isEmpty) return false;

    var successCount = 0;
    for (var i = 0; i < ingredients.length; i++) {
      final entry = ingredients[i];
      final res = await callApi(
        apiClient.createRecipe(outletId, {
          'userId': userId,
          'outletId': outletId,
          'itemId': itemId,
          'rawMaterialId': entry.key,
          'quantity': entry.value,
        }),
        showLoader: i == 0,
      );
      if (res != null) successCount++;
    }

    if (successCount > 0) {
      await loadRecipes();
      await loadDashboard();
    }
    return successCount == ingredients.length;
  }

  /// Creates, updates, and deletes recipe lines to match the submitted list.
  Future<bool> saveRecipesForItem({
    required String itemId,
    required List<RecipeLineInput> ingredients,
  }) async {
    if (ingredients.isEmpty) return false;

    final existing = recipesForItem(itemId);
    final existingById = {for (final r in existing) r.id: r};
    final keptIds = <String>{};

    var allOk = true;
    var showLoader = true;

    for (final ing in ingredients) {
      if (ing.id != null && ing.id!.isNotEmpty) {
        keptIds.add(ing.id!);
        final prev = existingById[ing.id!];
        if (prev != null &&
            prev.rawMaterialId == ing.rawMaterialId &&
            prev.quantity == ing.quantity) {
          continue;
        }
        final res = await callApi(
          apiClient.updateRecipe(outletId, ing.id!, {
            'rawMaterialId': ing.rawMaterialId,
            'quantity': ing.quantity,
          }),
          showLoader: showLoader,
        );
        showLoader = false;
        if (res == null) allOk = false;
      } else {
        final res = await callApi(
          apiClient.createRecipe(outletId, {
            'userId': userId,
            'outletId': outletId,
            'itemId': itemId,
            'rawMaterialId': ing.rawMaterialId,
            'quantity': ing.quantity,
          }),
          showLoader: showLoader,
        );
        showLoader = false;
        if (res == null) allOk = false;
      }
    }

    for (final r in existing) {
      if (!keptIds.contains(r.id)) {
        final res = await callApi(
          apiClient.deleteRecipe(outletId, r.id),
          showLoader: false,
        );
        if (res == null) allOk = false;
      }
    }

    await loadRecipes();
    await loadDashboard();
    return allOk;
  }

  Future<bool> updateRecipe({
    required String id,
    required String rawMaterialId,
    required double quantity,
  }) async {
    final res = await callApi(
      apiClient.updateRecipe(outletId, id, {
        'rawMaterialId': rawMaterialId,
        'quantity': quantity,
      }),
    );
    if (res != null) {
      await loadRecipes();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> deleteRecipe(String id) async {
    final res = await callApi(apiClient.deleteRecipe(outletId, id));
    if (res != null) {
      await loadRecipes();
      await loadDashboard();
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

  String menuItemName(String id) {
    return menuItems
            .firstWhereOrNull((i) => i.id == id)
            ?.itemName ??
        recipes.firstWhereOrNull((r) => r.itemId == id)?.itemName ??
        id;
  }
}
