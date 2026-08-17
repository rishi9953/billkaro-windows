import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';

class StockSummaryController extends BaseController {
  final items = <RawMaterialData>[].obs;
  final searchQuery = ''.obs;
  final statusFilter = 'ALL'.obs;
  final isLoading = false.obs;
  final hasLoaded = false.obs;

  String get outletId => appPref.selectedOutlet?.id ?? '';

  Future<void> loadStock({bool showLoader = true}) async {
    if (outletId.isEmpty) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.no_outlet_selected);
      return;
    }

    if (showLoader) isLoading.value = true;
    try {
      final res = await callApi(
        apiClient.getRawMaterials(
          outletId,
          searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
          null,
          null,
        ),
        showLoader: false,
      );
      if (res is Map && res['data'] is List) {
        items.value = (res['data'] as List)
            .map((e) => RawMaterialData.fromJson(Map<String, dynamic>.from(e)))
            .where((m) => m.isActive)
            .toList();
      } else {
        items.clear();
      }
      hasLoaded.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void setSearch(String value) {
    searchQuery.value = value;
  }

  void setStatusFilter(String status) {
    statusFilter.value = status;
  }

  List<RawMaterialData> get filteredItems {
    var list = items.toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q) ||
            item.materialCode.toLowerCase().contains(q) ||
            item.barcode.toLowerCase().contains(q) ||
            item.unit.toLowerCase().contains(q);
      }).toList();
    }
    final status = statusFilter.value;
    if (status != 'ALL') {
      list = list.where((i) => i.status == status).toList();
    }
    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return list;
  }

  int get totalCount => filteredItems.length;

  int get inStockCount =>
      filteredItems.where((i) => i.status == 'In Stock').length;

  int get lowStockCount =>
      filteredItems.where((i) => i.status == 'Low Stock').length;

  int get outOfStockCount =>
      filteredItems.where((i) => i.status == 'Out of Stock').length;

  double get totalStockValue =>
      filteredItems.fold(0.0, (sum, item) => sum + item.stockValue);
}
