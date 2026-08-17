import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';
import 'package:billkaro/utils/staff_access.dart';

class InventoryController extends BaseController {
  final isLoading = false.obs;
  final selectedTab = 0.obs;
  final searchQuery = ''.obs;
  final supplierSearchQuery = ''.obs;
  /// ALL | ACTIVE | INACTIVE
  final supplierStatusFilter = 'ALL'.obs;
  /// Null = all days
  final supplierDateFilter = Rxn<DateTime>();
  final showLowStockOnly = false.obs;
  /// ALL | In Stock | Low Stock | Out of Stock
  final rawMaterialStatusFilter = 'ALL'.obs;
  /// Empty string = all categories
  final rawMaterialCategoryFilter = ''.obs;
  /// Null = all days; otherwise only materials created / with activity that day
  final rawMaterialDateFilter = Rxn<DateTime>();
  final recipeSearchQuery = ''.obs;
  /// Empty = all menu items
  final recipeItemIdFilter = ''.obs;
  /// Empty = all materials
  final recipeMaterialIdFilter = ''.obs;
  /// Null = all days
  final recipeDateFilter = Rxn<DateTime>();

  /// Stock log filters (client-side on loaded transactions)
  final stockLogSearchQuery = ''.obs;
  /// Empty = all materials
  final stockLogMaterialIdFilter = ''.obs;
  /// ALL | PURCHASE | SALE | WASTAGE | ADJUSTMENT_IN | ADJUSTMENT_OUT | RETURN
  final stockLogTypeFilter = 'ALL'.obs;
  /// ALL | IN | OUT
  final stockLogDirectionFilter = 'ALL'.obs;
  /// Null = all days
  final stockLogDateFilter = Rxn<DateTime>();

  final dashboard = Rxn<InventoryDashboardData>();
  final rawMaterials = <RawMaterialData>[].obs;
  final rawMaterialCategoryItems = <RawMaterialCategoryData>[].obs;
  final suppliers = <SupplierData>[].obs;
  final transactions = <StockTransactionData>[].obs;
  final recipes = <RecipeData>[].obs;
  final menuItems = <ItemData>[].obs;
  final productStock = <ProductStockData>[].obs;
  final productStockSearch = ''.obs;
  final showProductLowStockOnly = false.obs;
  /// ALL | In Stock | Low Stock | Out of Stock
  final productStockStatusFilter = 'ALL'.obs;
  /// Empty string = all categories
  final productStockCategoryFilter = ''.obs;
  /// Empty = all items; otherwise only these item ids are included
  final productStockItemIdFilter = <String>{}.obs;
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
        loadMenuCategories(),
        loadSuppliers(),
        loadTransactions(limit: 500),
        loadRecipes(),
        loadMenuItems(),
        loadProductStock(),
      ]);
      // Persist category strings that exist on materials but not in the
      // raw_material_categories table (common after the category split).
      await syncOrphanRawMaterialCategories();
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
        null,
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
    if (outletId.isEmpty) return;
    final res = await callApi(
      apiClient.getRawMaterialCategories(outletId),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      final items = (res['data'] as List)
          .map(
            (e) => RawMaterialCategoryData.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .where((c) => c.categoryName.isNotEmpty)
          .toList()
        ..sort(
          (a, b) =>
              a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase()),
        );
      rawMaterialCategoryItems.value = items;
    }
  }

  /// Display names for dropdowns / filters.
  List<String> get rawMaterialCategories => rawMaterialCategoryItems
      .map((c) => c.categoryName.trim())
      .where((name) => name.isNotEmpty)
      .toList();

  /// Categories for chips/panel/counts: API rows plus orphan strings on materials.
  List<RawMaterialCategoryData> get displayRawMaterialCategoryItems {
    final byKey = <String, RawMaterialCategoryData>{};
    for (final c in rawMaterialCategoryItems) {
      final key = c.categoryName.trim().toLowerCase();
      if (key.isEmpty) continue;
      byKey[key] = c;
    }
    for (final m in rawMaterials) {
      final name = m.category.trim();
      final key = name.toLowerCase();
      if (key.isEmpty || byKey.containsKey(key)) continue;
      byKey[key] = RawMaterialCategoryData(
        id: '',
        categoryName: name,
        userId: userId,
        outletId: outletId,
      );
    }
    return byKey.values.toList()
      ..sort(
        (a, b) => a.categoryName.toLowerCase().compareTo(
              b.categoryName.toLowerCase(),
            ),
      );
  }

  int rawMaterialCountForCategory(String categoryName) {
    final key = categoryName.trim().toLowerCase();
    if (key.isEmpty) return 0;
    return rawMaterials
        .where((m) => m.category.trim().toLowerCase() == key)
        .length;
  }

  /// Menu item categories (separate from raw material categories).
  Future<void> loadMenuCategories() async {
    final selectedOutletId = appPref.selectedOutlet?.id;
    if (selectedOutletId == null) return;
    final loaded = await OfflineCategoryLoader.load(
      outletId: selectedOutletId,
      fetchFromApi: () =>
          callApi(apiClient.getCategories(selectedOutletId), showLoader: false),
    );
    categories.value = loaded;
  }

  List<String> get rawMaterialListCategories {
    final cats = <String>{
      ...rawMaterialCategories,
      ...rawMaterials
          .map((e) => e.category.trim())
          .where((c) => c.isNotEmpty),
    }.toList();
    cats.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cats;
  }

  /// Upsert material category strings missing from raw_material_categories.
  Future<void> syncOrphanRawMaterialCategories() async {
    if (outletId.isEmpty || userId.isEmpty) return;
    final existing = rawMaterialCategoryItems
        .map((c) => c.categoryName.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    final orphans = <String>{};
    for (final m in rawMaterials) {
      final name = m.category.trim();
      final key = name.toLowerCase();
      if (key.isEmpty || key == 'none' || existing.contains(key)) continue;
      orphans.add(key);
    }
    if (orphans.isEmpty) return;
    var createdAny = false;
    for (final name in orphans) {
      if (await _ensureRawMaterialCategory(name, silent: true)) {
        createdAny = true;
      }
    }
    if (createdAny) await loadRawMaterialCategories();
  }

  /// Quick-add a category from Inventory (raw materials) and refresh lists.
  Future<String?> showQuickAddCategoryDialog() async {
    final context = Get.context;
    if (context == null) return null;

    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isSaving = false.obs;

    try {
      return await Get.dialog<String>(
        Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Builder(
              builder: (dialogContext) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.category_outlined,
                                  color: AppColor.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  loc.add_category,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: loc.cancel,
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.close),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Text(
                            loc.enter_category_name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: TextFormField(
                            controller: nameController,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: loc.category_name,
                              hintText: loc.enter_category_name,
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty ||
                                  trimmed.toLowerCase() == 'none') {
                                return loc.category_name_cannot_be_empty;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) async {
                              if (isSaving.value) return;
                              await _submitQuickAddCategory(
                                formKey: formKey,
                                nameController: nameController,
                                isSaving: isSaving,
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Obx(
                            () => Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving.value
                                        ? null
                                        : () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                      side:
                                          BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: Text(loc.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving.value
                                        ? null
                                        : () => _submitQuickAddCategory(
                                              formKey: formKey,
                                              nameController: nameController,
                                              isSaving: isSaving,
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          AppColor.primary.withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: isSaving.value
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(loc.add_category),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _submitQuickAddCategory({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required RxBool isSaving,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isSaving.value) return;

    isSaving.value = true;
    try {
      final created = await createCategoryQuick(nameController.text);
      if (created != null) {
        Get.back(result: created);
      }
    } finally {
      isSaving.value = false;
    }
  }

  /// Creates a category via API (or returns existing match), then refreshes lists.
  Future<String?> createCategoryQuick(String rawName) async {
    final ok = await _ensureRawMaterialCategory(rawName, silent: false);
    if (!ok) return null;
    final normalized = rawName.trim().toLowerCase();
    return rawMaterialCategoryItems
            .firstWhereOrNull(
              (c) => c.categoryName.trim().toLowerCase() == normalized,
            )
            ?.categoryName ??
        normalized;
  }

  /// Ensures [rawName] exists in raw_material_categories. Returns false on failure.
  Future<bool> _ensureRawMaterialCategory(
    String rawName, {
    required bool silent,
  }) async {
    final name = rawName.trim();
    if (name.isEmpty || name.toLowerCase() == 'none') {
      if (!silent) {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(description: loc.category_name_cannot_be_empty);
      }
      return false;
    }

    final normalized = name.toLowerCase();
    final existing = rawMaterialCategoryItems.firstWhereOrNull(
      (c) => c.categoryName.trim().toLowerCase() == normalized,
    );
    if (existing != null) return true;

    if (outletId.isEmpty || userId.isEmpty) return false;

    final response = await callApi(
      apiClient.addRawMaterialCategory(outletId, {
        'userId': userId,
        'outletId': outletId,
        'categoryName': normalized,
      }),
      showLoader: false,
    );

    if (response == null || response['status'] != 'success') {
      if (silent) {
        // Unique/duplicate races are fine; other failures stay silent.
        final msg =
            (response is Map ? response['message'] : null)?.toString().toLowerCase() ??
                '';
        return msg.contains('exist') || msg.contains('duplicate');
      }
      final loc = AppLocalizations.of(Get.context!)!;
      showError(
        description: response?['message'] ?? loc.failed_to_add_category,
      );
      return false;
    }

    if (!silent) {
      await loadRawMaterialCategories();
      final loc = AppLocalizations.of(Get.context!)!;
      showSuccess(
        description: response['message'] ?? loc.category_added_successfully,
      );
    }
    return true;
  }

  Future<bool> deleteRawMaterialCategoryById(String id) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    if (id.trim().isEmpty || outletId.isEmpty) return false;
    final res = await callApi(
      apiClient.deleteRawMaterialCategory(outletId, id),
      showLoader: true,
    );
    if (res != null && (res is! Map || res['status'] == 'success')) {
      final removed = rawMaterialCategoryItems.firstWhereOrNull((c) => c.id == id);
      if (removed != null &&
          rawMaterialCategoryFilter.value.trim().toLowerCase() ==
              removed.categoryName.trim().toLowerCase()) {
        rawMaterialCategoryFilter.value = '';
      }
      await loadRawMaterialCategories();
      showSuccess(description: 'Category deleted successfully');
      return true;
    }
    showError(
      description: (res is Map ? res['message'] : null) ??
          'Failed to delete category',
    );
    return false;
  }

  List<RawMaterialData> get filteredRawMaterials {
    var items = rawMaterials.toList();
    final status = rawMaterialStatusFilter.value;
    if (status != 'ALL') {
      items = items.where((m) => m.status == status).toList();
    } else if (showLowStockOnly.value) {
      items = items
          .where((m) => m.status == 'Low Stock' || m.status == 'Out of Stock')
          .toList();
    }
    final cat = rawMaterialCategoryFilter.value.trim().toLowerCase();
    if (cat.isNotEmpty) {
      items = items
          .where((m) => m.category.trim().toLowerCase() == cat)
          .toList();
    }
    final date = rawMaterialDateFilter.value;
    if (date != null) {
      final dayIds = rawMaterialIdsForDay(date);
      items = items.where((m) {
        if (_isSameCalendarDay(m.createdAt, date)) return true;
        return dayIds.contains(m.id);
      }).toList();
    }
    return items;
  }

  Set<String> rawMaterialIdsForDay(DateTime day) {
    final ids = <String>{};
    for (final t in transactions) {
      final created = DateTime.tryParse(t.createdAt)?.toLocal();
      if (_isSameCalendarDay(created, day) && t.rawMaterialId.isNotEmpty) {
        ids.add(t.rawMaterialId);
      }
    }
    return ids;
  }

  static DateTime _calendarDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  bool get isRawMaterialDateToday {
    final date = rawMaterialDateFilter.value;
    if (date == null) return false;
    return _isSameCalendarDay(date, DateTime.now());
  }

  bool get hasRawMaterialDateFilter => rawMaterialDateFilter.value != null;

  bool _isSameCalendarDay(DateTime? value, DateTime day) {
    if (value == null) return false;
    return value.year == day.year &&
        value.month == day.month &&
        value.day == day.day;
  }

  String get rawMaterialDateFilterLabel {
    final date = rawMaterialDateFilter.value;
    if (date == null) return 'All days';
    if (isRawMaterialDateToday) return 'Today';
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthShort(date.month)} ${date.year}';
  }

  String get rawMaterialStockValueLabel =>
      hasRawMaterialDateFilter
          ? (isRawMaterialDateToday ? "Today's Stock Value" : 'Stock Value')
          : 'Stock Value';

  static String _monthShort(int month) {
    const months = [
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
    return months[month - 1];
  }

  void clearRawMaterialDateFilter() {
    rawMaterialDateFilter.value = null;
  }

  Future<void> setRawMaterialDateFilter(DateTime? date) async {
    rawMaterialDateFilter.value =
        date == null ? null : _calendarDay(date);
    if (date != null) {
      await loadTransactions(limit: 500);
    }
  }

  double get rawMaterialTotalValue =>
      filteredRawMaterials.fold(0.0, (sum, m) => sum + m.total);

  int get rawMaterialLowCount => rawMaterials
      .where((m) => m.status == 'Low Stock' || m.status == 'Out of Stock')
      .length;

  int get rawMaterialOutCount =>
      rawMaterials.where((m) => m.status == 'Out of Stock').length;

  String rawMaterialSupplierName(String? supplierId) {
    final id = (supplierId ?? '').trim();
    if (id.isEmpty) return '';
    return suppliers.firstWhereOrNull((s) => s.id == id)?.name ?? '';
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

  List<SupplierData> get filteredSuppliers {
    var items = suppliers.toList();

    final status = supplierStatusFilter.value.trim().toUpperCase();
    if (status == 'ACTIVE') {
      items = items.where((s) => s.isActive).toList();
    } else if (status == 'INACTIVE') {
      items = items.where((s) => !s.isActive).toList();
    }

    final date = supplierDateFilter.value;
    if (date != null) {
      items = items
          .where((s) => _isSameCalendarDay(s.createdAt, date))
          .toList();
    }

    final q = supplierSearchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((s) {
        return s.name.toLowerCase().contains(q) ||
            (s.phone ?? '').toLowerCase().contains(q) ||
            (s.email ?? '').toLowerCase().contains(q) ||
            (s.gstNumber ?? '').toLowerCase().contains(q) ||
            (s.vendorNo ?? '').toLowerCase().contains(q) ||
            (s.company ?? '').toLowerCase().contains(q) ||
            (s.contactPerson ?? '').toLowerCase().contains(q) ||
            (s.address ?? '').toLowerCase().contains(q) ||
            (s.addressLine1 ?? '').toLowerCase().contains(q) ||
            (s.addressLine2 ?? '').toLowerCase().contains(q) ||
            (s.city ?? '').toLowerCase().contains(q) ||
            (s.state ?? '').toLowerCase().contains(q) ||
            (s.pinCode ?? '').toLowerCase().contains(q);
      }).toList();
    }

    items.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return items;
  }

  bool get hasSupplierDateFilter => supplierDateFilter.value != null;

  bool get hasSupplierFilters {
    return supplierSearchQuery.value.trim().isNotEmpty ||
        (supplierStatusFilter.value.trim().isNotEmpty &&
            supplierStatusFilter.value.trim().toUpperCase() != 'ALL') ||
        hasSupplierDateFilter;
  }

  bool get isSupplierDateToday {
    final date = supplierDateFilter.value;
    if (date == null) return false;
    return _isSameCalendarDay(date, DateTime.now());
  }

  String get supplierDateFilterLabel {
    final date = supplierDateFilter.value;
    if (date == null) return 'All days';
    if (isSupplierDateToday) return 'Today';
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthShort(date.month)} ${date.year}';
  }

  int get supplierActiveCount =>
      filteredSuppliers.where((s) => s.isActive).length;

  int get supplierInactiveCount =>
      filteredSuppliers.where((s) => !s.isActive).length;

  void clearSupplierDateFilter() {
    supplierDateFilter.value = null;
  }

  void setSupplierDateFilter(DateTime? date) {
    supplierDateFilter.value = date == null ? null : _calendarDay(date);
  }

  void clearSupplierFilters() {
    supplierSearchQuery.value = '';
    supplierStatusFilter.value = 'ALL';
    supplierDateFilter.value = null;
  }

  Future<void> loadTransactions({int limit = 50}) async {
    final res = await callApi(
      apiClient.getStockTransactions(outletId, null, null, 1, limit),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      transactions.value = (res['data'] as List)
          .map((e) => StockTransactionData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  static bool isStockInType(String type) {
    final t = type.trim().toUpperCase();
    return t.contains('IN') || t == 'PURCHASE' || t == 'RETURN';
  }

  List<StockTransactionData> get filteredTransactions {
    var items = transactions.toList();

    final materialId = stockLogMaterialIdFilter.value.trim();
    if (materialId.isNotEmpty) {
      items = items.where((t) => t.rawMaterialId == materialId).toList();
    }

    final type = stockLogTypeFilter.value.trim().toUpperCase();
    if (type.isNotEmpty && type != 'ALL') {
      items = items.where((t) => t.type.trim().toUpperCase() == type).toList();
    }

    final direction = stockLogDirectionFilter.value.trim().toUpperCase();
    if (direction == 'IN') {
      items = items.where((t) => isStockInType(t.type)).toList();
    } else if (direction == 'OUT') {
      items = items.where((t) => !isStockInType(t.type)).toList();
    }

    final date = stockLogDateFilter.value;
    if (date != null) {
      items = items.where((t) {
        final created = DateTime.tryParse(t.createdAt)?.toLocal();
        return _isSameCalendarDay(created, date);
      }).toList();
    }

    final q = stockLogSearchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((t) {
        final name = materialName(t.rawMaterialId).toLowerCase();
        final typeLabel = t.type.replaceAll('_', ' ').toLowerCase();
        final notes = (t.notes ?? '').toLowerCase();
        final reference = (t.reference ?? '').toLowerCase();
        final qty = t.quantity.toString();
        return name.contains(q) ||
            typeLabel.contains(q) ||
            notes.contains(q) ||
            reference.contains(q) ||
            qty.contains(q);
      }).toList();
    }

    return items;
  }

  bool get hasStockLogDateFilter => stockLogDateFilter.value != null;

  bool get hasStockLogFilters {
    return stockLogSearchQuery.value.trim().isNotEmpty ||
        stockLogMaterialIdFilter.value.trim().isNotEmpty ||
        (stockLogTypeFilter.value.trim().isNotEmpty &&
            stockLogTypeFilter.value.trim().toUpperCase() != 'ALL') ||
        (stockLogDirectionFilter.value.trim().isNotEmpty &&
            stockLogDirectionFilter.value.trim().toUpperCase() != 'ALL') ||
        hasStockLogDateFilter;
  }

  bool get isStockLogDateToday {
    final date = stockLogDateFilter.value;
    if (date == null) return false;
    return _isSameCalendarDay(date, DateTime.now());
  }

  String get stockLogDateFilterLabel {
    final date = stockLogDateFilter.value;
    if (date == null) return 'All days';
    if (isStockLogDateToday) return 'Today';
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthShort(date.month)} ${date.year}';
  }

  int get stockLogInCount =>
      filteredTransactions.where((t) => isStockInType(t.type)).length;

  int get stockLogOutCount =>
      filteredTransactions.where((t) => !isStockInType(t.type)).length;

  void clearStockLogDateFilter() {
    stockLogDateFilter.value = null;
  }

  void setStockLogDateFilter(DateTime? date) {
    stockLogDateFilter.value =
        date == null ? null : _calendarDay(date);
  }

  void clearStockLogFilters() {
    stockLogSearchQuery.value = '';
    stockLogMaterialIdFilter.value = '';
    stockLogTypeFilter.value = 'ALL';
    stockLogDirectionFilter.value = 'ALL';
    stockLogDateFilter.value = null;
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
        null,
      ),
      showLoader: false,
    );
    if (res is Map && res['data'] is List) {
      productStock.value = (res['data'] as List)
          .map((e) => ProductStockData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  List<String> get productStockCategories {
    final cats = <String>{
      ...categories
          .map((c) => c.categoryName.trim())
          .where((name) => name.isNotEmpty),
      ...productStock
          .map((e) => e.category.trim())
          .where((c) => c.isNotEmpty),
      ...menuItems
          .map((e) => e.category.trim())
          .where((c) => c.isNotEmpty),
    }.toList();
    cats.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cats;
  }

  List<ProductStockData> get filteredProductStock {
    var items = productStock.toList();
    final status = productStockStatusFilter.value;
    if (status != 'ALL') {
      items = items.where((i) => i.status == status).toList();
    } else if (showProductLowStockOnly.value) {
      items = items
          .where((i) => i.status == 'Low Stock' || i.status == 'Out of Stock')
          .toList();
    }
    final cat = productStockCategoryFilter.value.trim();
    if (cat.isNotEmpty) {
      items = items.where((i) => i.category.trim() == cat).toList();
    }
    final selectedIds = productStockItemIdFilter;
    if (selectedIds.isNotEmpty) {
      items = items.where((i) => selectedIds.contains(i.id)).toList();
    }
    return items;
  }

  double get productStockTotalValue {
    return filteredProductStock.fold(0.0, (sum, item) => sum + item.total);
  }

  void setProductStockItemFilter(Iterable<String> ids) {
    productStockItemIdFilter
      ..clear()
      ..addAll(ids);
    productStockItemIdFilter.refresh();
  }

  void clearProductStockItemFilter() {
    productStockItemIdFilter.clear();
    productStockItemIdFilter.refresh();
  }

  int get productStockLowCount => productStock
      .where((i) => i.status == 'Low Stock' || i.status == 'Out of Stock')
      .length;

  int get productStockOutCount =>
      productStock.where((i) => i.status == 'Out of Stock').length;

  Future<bool> adjustProductStock({
    required String itemId,
    required String adjustmentType,
    required double quantity,
    String reason = 'Other',
    String? notes,
    double? costPrice,
    String? sku,
    String? barcode,
    double? taxPercent,
    String? category,
    String? supplierId,
    bool removeTracking = false,
  }) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    final res = await callApi(
      apiClient.adjustProductStock(outletId, itemId, {
        'userId': userId,
        'adjustmentType': adjustmentType,
        'quantity': quantity,
        'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (costPrice != null) 'costPrice': costPrice,
        if (sku != null && sku.isNotEmpty) 'sku': sku,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        if (taxPercent != null) 'taxPercent': taxPercent,
        if (category != null && category.isNotEmpty) 'category': category,
        if (supplierId != null && supplierId.isNotEmpty) 'supplierId': supplierId,
        if (removeTracking) 'removeTracking': true,
      }),
    );
    if (res is Map && res['status'] == 'success') {
      await Future.wait([loadProductStock(), loadDashboard()]);
      return true;
    }
    return false;
  }

  Future<bool> deleteProductStock(String itemId) async {
    return adjustProductStock(
      itemId: itemId,
      adjustmentType: 'ADJUSTMENT',
      quantity: 0,
      reason: 'Other',
      notes: 'Removed from Item Stock',
      removeTracking: true,
    );
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
    var items = recipes.toList();

    final itemId = recipeItemIdFilter.value.trim();
    if (itemId.isNotEmpty) {
      items = items.where((r) => r.itemId == itemId).toList();
    }

    final materialId = recipeMaterialIdFilter.value.trim();
    if (materialId.isNotEmpty) {
      items = items.where((r) => r.rawMaterialId == materialId).toList();
    }

    final date = recipeDateFilter.value;
    if (date != null) {
      items = items
          .where((r) => _isSameCalendarDay(r.createdAt, date))
          .toList();
    }

    final q = recipeSearchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((r) {
        final itemName = r.itemName.trim().isNotEmpty
            ? r.itemName
            : menuItemName(r.itemId);
        return itemName.toLowerCase().contains(q) ||
            r.rawMaterialName.toLowerCase().contains(q) ||
            r.displayUnit.toLowerCase().contains(q) ||
            r.quantity.toString().contains(q);
      }).toList();
    }

    return items;
  }

  Map<String, List<RecipeData>> get recipesGroupedByItem {
    final map = <String, List<RecipeData>>{};
    for (final r in filteredRecipes) {
      map.putIfAbsent(r.itemId, () => []).add(r);
    }
    return map;
  }

  bool get hasRecipeDateFilter => recipeDateFilter.value != null;

  bool get hasRecipeFilters {
    return recipeSearchQuery.value.trim().isNotEmpty ||
        recipeItemIdFilter.value.trim().isNotEmpty ||
        recipeMaterialIdFilter.value.trim().isNotEmpty ||
        hasRecipeDateFilter;
  }

  bool get isRecipeDateToday {
    final date = recipeDateFilter.value;
    if (date == null) return false;
    return _isSameCalendarDay(date, DateTime.now());
  }

  String get recipeDateFilterLabel {
    final date = recipeDateFilter.value;
    if (date == null) return 'All days';
    if (isRecipeDateToday) return 'Today';
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthShort(date.month)} ${date.year}';
  }

  int get recipeFilteredItemCount => recipesGroupedByItem.length;

  int get recipeFilteredLineCount => filteredRecipes.length;

  void clearRecipeDateFilter() {
    recipeDateFilter.value = null;
  }

  void setRecipeDateFilter(DateTime? date) {
    recipeDateFilter.value = date == null ? null : _calendarDay(date);
  }

  void clearRecipeFilters() {
    recipeSearchQuery.value = '';
    recipeItemIdFilter.value = '';
    recipeMaterialIdFilter.value = '';
    recipeDateFilter.value = null;
  }

  Future<bool> createRawMaterial(Map<String, dynamic> body) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    final category = (body['category'] as String?)?.trim() ?? '';
    if (category.isNotEmpty) {
      await _ensureRawMaterialCategory(category, silent: true);
    }
    final res = await callApi(
      apiClient.createRawMaterial(outletId, {
        ...body,
        'userId': userId,
        'outletId': outletId,
      }),
    );
    if (res != null) {
      await loadRawMaterials();
      await loadRawMaterialCategories();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> updateRawMaterial(
    String id,
    Map<String, dynamic> body,
  ) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    final category = (body['category'] as String?)?.trim() ?? '';
    if (category.isNotEmpty) {
      await _ensureRawMaterialCategory(category, silent: true);
    }
    final res = await callApi(apiClient.updateRawMaterial(outletId, id, body));
    if (res != null) {
      await loadRawMaterials();
      await loadRawMaterialCategories();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> deleteRawMaterial(String id) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    final res = await callApi(apiClient.deleteRawMaterial(outletId, id));
    if (res != null) {
      await loadRawMaterials();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> createSupplier(Map<String, dynamic> body) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
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
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    final res = await callApi(apiClient.updateSupplier(outletId, id, body));
    if (res != null) {
      await loadSuppliers();
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> deleteSupplier(String id) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    final res = await callApi(apiClient.deleteSupplier(outletId, id));
    final ok = res is Map && res['status']?.toString() == 'success';
    if (ok) {
      suppliers.removeWhere((s) => s.id == id);
      await loadSuppliers();
      await loadDashboard();
      return true;
    }
    if (res is Map) {
      final message = res['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        showError(description: message);
      }
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
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
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
      await Future.wait([
        loadRecipes(),
        loadRawMaterials(),
        loadTransactions(),
        loadDashboard(),
      ]);
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
      await Future.wait([
        loadRecipes(),
        loadRawMaterials(),
        loadTransactions(),
        loadDashboard(),
      ]);
    }
    return successCount == ingredients.length;
  }

  /// Creates, updates, and deletes recipe lines to match the submitted list.
  /// Incoming lines without an id are matched to existing rows by rawMaterialId
  /// so linking/copying a recipe does not hit unique-constraint conflicts.
  Future<bool> saveRecipesForItem({
    required String itemId,
    required List<RecipeLineInput> ingredients,
  }) async {
    if (ingredients.isEmpty) return false;

    final existing = recipesForItem(itemId);
    final existingById = {for (final r in existing) r.id: r};
    final existingByMaterial = {
      for (final r in existing) r.rawMaterialId: r,
    };
    final keptIds = <String>{};

    var allOk = true;
    var showLoader = true;

    for (final ing in ingredients) {
      var recipeId = (ing.id ?? '').trim();
      if (recipeId.isEmpty) {
        recipeId = existingByMaterial[ing.rawMaterialId]?.id ?? '';
      }

      if (recipeId.isNotEmpty && existingById.containsKey(recipeId)) {
        keptIds.add(recipeId);
        final prev = existingById[recipeId]!;
        if (prev.rawMaterialId == ing.rawMaterialId &&
            prev.quantity == ing.quantity &&
            prev.displayUnit.toUpperCase() == ing.unit.toUpperCase()) {
          continue;
        }
        final res = await callApi(
          apiClient.updateRecipe(outletId, recipeId, {
            'userId': userId,
            'rawMaterialId': ing.rawMaterialId,
            'quantity': ing.quantity,
            'unit': ing.unit,
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
            'unit': ing.unit,
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

    await Future.wait([
      loadRecipes(),
      loadRawMaterials(),
      loadTransactions(limit: 500),
      loadDashboard(),
    ]);
    return allOk;
  }

  Future<bool> updateRecipe({
    required String id,
    required String rawMaterialId,
    required double quantity,
  }) async {
    final res = await callApi(
      apiClient.updateRecipe(outletId, id, {
        'userId': userId,
        'rawMaterialId': rawMaterialId,
        'quantity': quantity,
      }),
    );
    if (res != null) {
      await Future.wait([
        loadRecipes(),
        loadRawMaterials(),
        loadTransactions(),
        loadDashboard(),
      ]);
      return true;
    }
    return false;
  }

  Future<bool> deleteRecipe(String id) async {
    final res = await callApi(apiClient.deleteRecipe(outletId, id));
    if (res != null) {
      await Future.wait([
        loadRecipes(),
        loadRawMaterials(),
        loadTransactions(),
        loadDashboard(),
      ]);
      return true;
    }
    return false;
  }

  /// Deletes all recipe ingredient lines for a menu item.
  Future<bool> deleteRecipesForItem(String itemId) async {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return false;
    final lines = recipesForItem(itemId);
    if (lines.isEmpty) return true;

    var allOk = true;
    for (var i = 0; i < lines.length; i++) {
      final res = await callApi(
        apiClient.deleteRecipe(outletId, lines[i].id),
        showLoader: i == 0,
      );
      if (res == null) allOk = false;
    }
    await Future.wait([
      loadRecipes(),
      loadRawMaterials(),
      loadTransactions(),
      loadDashboard(),
    ]);
    return allOk;
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
