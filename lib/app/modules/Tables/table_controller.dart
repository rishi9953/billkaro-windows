import 'package:billkaro/app/Database/app_database.dart' as dbs;
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/config.dart';

enum TableStatus { available, occupied, billing }

enum TableFilter { all, available, occupied, billing }

class TableWithStatus {
  final TableModel table;
  final TableStatus status;
  final OrderModel? currentOrder;

  TableWithStatus({
    required this.table,
    required this.status,
    this.currentOrder,
  });

  bool get isAvailable => status == TableStatus.available;
}

class TableController extends BaseController {
  final db = Get.find<dbs.AppDatabase>();

  final RxList<TableWithStatus> tables = <TableWithStatus>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<TableFilter> selectedFilter = TableFilter.all.obs;
  final RxString errorMessage = ''.obs;

  int get seatingCapacityLimit =>
      _parseSeatingCapacityLimit(appPref.selectedOutlet?.seatingCapacity);

  @override
  void onInit() {
    super.onInit();
    loadTables();
  }

  Future<void> loadTables() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      isLoading.value = false;
      return;
    }

    List<TableModel> tableList = [];

    try {
      final response = await callApi(
        apiClient.getOutletTables(outletId),
        showLoader: false,
      );

      if (response?.status == 'success') {
        tableList = response!.data
            .map((e) => TableModel.fromTableData(e))
            .toList();
      }
    } catch (_) {
      errorMessage.value = 'Unable to load tables from server';
    }

    if (tableList.isEmpty) {
      tableList = _defaultTables();
    }

    List<OrderModel> orders = <OrderModel>[];
    try {
      orders = await db.getAllOrders(outletId: outletId);
    } catch (_) {
      errorMessage.value = 'Unable to load local orders';
    }

    tables.value = tableList.map((table) {
      final tableOrders = orders
          .where((o) => _matchesTable(o, table))
          .toList(growable: false);
      final order = _findCurrentOrderForTable(orders, table);
      final status = _resolveStatus(
        order: order,
        table: table,
        hasLocalHistory: tableOrders.isNotEmpty,
      );

      return TableWithStatus(table: table, status: status, currentOrder: order);
    }).toList();

    isLoading.value = false;
  }

  String _normalizeTableNumber(String raw) {
    var value = raw.trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^table\s*'), '');
    value = value.replaceAll(RegExp(r'\s+'), '');
    return value;
  }

  Set<String> _tableKeys(TableModel table) {
    return {
      _normalizeTableNumber(table.tableNumber),
      _normalizeTableNumber(table.displayName),
    }..removeWhere((e) => e.isEmpty);
  }

  bool _matchesTable(OrderModel order, TableModel table) {
    final orderKey = _normalizeTableNumber(order.tableNumber ?? '');
    if (orderKey.isEmpty) return false;
    return _tableKeys(table).contains(orderKey);
  }

  bool _isActiveOrder(OrderModel order) =>
      order.status.trim().toLowerCase() != 'closed';

  DateTime _parseSafeDate(String? value) {
    if (value == null || value.isEmpty)
      return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  OrderModel? _findCurrentOrderForTable(
    List<OrderModel> orders,
    TableModel table,
  ) {
    final matches = orders
        .where((o) => _isActiveOrder(o) && _matchesTable(o, table))
        .toList(growable: false);
    if (matches.isEmpty) return null;

    matches.sort(
      (a, b) =>
          _parseSafeDate(b.updatedAt).compareTo(_parseSafeDate(a.updatedAt)),
    );
    return matches.first;
  }

  TableStatus _resolveStatus({
    OrderModel? order,
    required TableModel table,
    required bool hasLocalHistory,
  }) {
    if (order != null) {
      final orderStatus = order.status.trim().toLowerCase();
      if (orderStatus == 'billing') return TableStatus.billing;
      return TableStatus.occupied;
    }

    final apiStatus = table.status.trim().toLowerCase();
    if (apiStatus == 'billing') return TableStatus.billing;
    if (apiStatus == 'occupied' ||
        apiStatus == 'busy' ||
        apiStatus == 'reserved') {
      return TableStatus.occupied;
    }
    if (hasLocalHistory) {
      return TableStatus.available;
    }
    if ((table.currentBillNumber ?? '').trim().isNotEmpty) {
      return TableStatus.billing;
    }

    return TableStatus.available;
  }

  List<TableWithStatus> get filteredTables {
    final query = searchQuery.value.trim().toLowerCase();
    return tables
        .where((tws) {
          final matchesQuery =
              query.isEmpty ||
              tws.table.displayName.toLowerCase().contains(query);

          final matchesFilter = switch (selectedFilter.value) {
            TableFilter.all => true,
            TableFilter.available => tws.status == TableStatus.available,
            TableFilter.occupied => tws.status == TableStatus.occupied,
            TableFilter.billing => tws.status == TableStatus.billing,
          };

          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
  }

  void setSearchQuery(String value) => searchQuery.value = value;
  void setFilter(TableFilter filter) => selectedFilter.value = filter;

  int _parseSeatingCapacityLimit(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final value = raw.trim().toLowerCase();

    if (value == '0') return 0;
    if (value == '0-10') return 10;
    if (value == '10-20') return 20;
    if (value == '20-50') return 50;
    if (value == '50-100') return 100;
    if (value == '100+') return 100;

    final numeric = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    return numeric ?? 0;
  }

  bool get canAddMoreTables {
    final limit = seatingCapacityLimit;
    if (limit <= 0) return false;
    return tables.length < limit;
  }

  Future<bool> addTable(String rawTableNumber) async {
    final input = rawTableNumber.trim();
    if (input.isEmpty) {
      showError(description: 'Please enter table number');
      return false;
    }

    final limit = seatingCapacityLimit;
    if (limit <= 0) {
      showError(
        description: 'Set outlet seating capacity first before adding tables',
      );
      return false;
    }

    if (!canAddMoreTables) {
      showError(
        description: 'Cannot add more than $limit tables (seating capacity)',
      );
      return false;
    }

    final normalizedInput = _normalizeTableNumber(input);
    final exists = tables.any(
      (t) => _normalizeTableNumber(t.table.tableNumber) == normalizedInput,
    );
    if (exists) {
      showError(description: 'This table already exists');
      return false;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: 'Please select an outlet first');
      return false;
    }

    final response = await callApi(
      apiClient.createTable({
        'outletId': outletId,
        'tableNumber': input,
        'status': 'available',
      }),
    );

    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: 'Table added successfully');
      return true;
    }

    showError(description: response?['message'] ?? 'Failed to add table');
    return false;
  }

  Future<bool> deleteTable(TableWithStatus tws) async {
    if (!tws.isAvailable) {
      showError(description: 'Only available tables can be deleted');
      return false;
    }

    if (tws.currentOrder != null) {
      showError(description: 'Cannot delete table with active order');
      return false;
    }

    final response = await callApi(apiClient.deleteTable(tws.table.id));
    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: 'Table deleted successfully');
      return true;
    }

    showError(description: response?['message'] ?? 'Failed to delete table');
    return false;
  }

  Future<bool> resetAllTables() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: 'Please select an outlet first');
      return false;
    }

    final response = await callApi(apiClient.resetAllTable(outletId));
    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: 'All tables reset successfully');
      return true;
    }

    showError(description: response?['message'] ?? 'Failed to reset all tables');
    return false;
  }

  Future<void> onTableTap(TableWithStatus tws) async {
    if (tws.isAvailable) {
      await Get.toNamed(
        AppRoute.addOrder,
        arguments: {
          'orderFrom': 'Dine In',
          'tableNumber': tws.table.displayName,
        },
      );
      await loadTables();
      return;
    }

    if (tws.currentOrder != null) {
      await Get.toNamed(
        AppRoute.addOrder,
        arguments: {'order': tws.currentOrder, 'isEdit': true},
      );
      await loadTables();
      return;
    }

    showError(description: 'No active order details found for this table');
  }

  Future<void> refresh() => loadTables();

  List<TableModel> _defaultTables() {
    return List.generate(
      12,
      (i) => TableModel(
        id: 'table_${i + 1}',
        tableNumber: '${i + 1}',
        status: 'available',
      ),
    );
  }

  /// CALL THIS AFTER PAYMENT SUCCESS
  Future<void> closeOrderAndFreeTable(OrderModel order) async {
    // await db.updateOrder(
    //   order.copyWith(
    //     status: 'Closed',
    //     paymentStatus: 'Completed',
    //     closedAt: DateTime.now(),
    //   ),
    // );

    loadTables();
  }
}
