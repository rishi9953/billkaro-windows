import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Tables/merge_tables_dialog.dart';
import 'package:billkaro/app/modules/Tables/table_form_dialog.dart';
import 'package:billkaro/app/modules/Tables/table_qr_print_service.dart';
import 'package:billkaro/app/modules/Tables/table_qr_service.dart';
import 'package:billkaro/app/Database/app_database.dart' as dbs;
import 'package:billkaro/utils/outlet_seating.dart';
import 'package:billkaro/utils/qr_menu_url_config.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/tables/table_reservation_model.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

enum TableStatus { available, reserved, occupied, billing }

enum TableFilter { all, available, reserved, occupied, merged }

class TableWithStatus {
  final TableModel table;
  final TableStatus status;
  final OrderModel? currentOrder;
  final TableReservationModel? upcomingReservation;

  TableWithStatus({
    required this.table,
    required this.status,
    this.currentOrder,
    this.upcomingReservation,
  });

  bool get isAvailable => status == TableStatus.available;
  bool get isReserved => status == TableStatus.reserved;
}

class TableController extends BaseController {
  final db = Get.find<dbs.AppDatabase>();

  final RxList<TableWithStatus> tables = <TableWithStatus>[].obs;
  final RxList<TableReservationModel> reservations =
      <TableReservationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<TableFilter> selectedFilter = TableFilter.all.obs;
  final RxString errorMessage = ''.obs;
  final RxString reservationFilterDate = ''.obs;

  int get seatingCapacityLimit =>
      parseSeatingCapacityLimit(appPref.selectedOutlet?.seatingCapacity);

  int get totalUsedSeats =>
      sumTableSeats(tables.map((t) => t.table.seatingCapacity));

  int get remainingSeats =>
      remainingOutletSeats(totalUsedSeats, seatingCapacityLimit);

  String? _tableSeatsValidationError(
    int newTableSeats, {
    int excludeTableSeats = 0,
  }) {
    final loc = AppLocalizations.of(Get.context!)!;
    final max = seatingCapacityLimit;
    if (max <= 0) {
      return loc.set_outlet_seating_capacity_first;
    }

    final used = totalUsedSeats - excludeTableSeats;
    if (newTableSeats > max) {
      return loc.table_seats_exceed_outlet(max);
    }
    if (!canFitTableSeats(
      usedSeats: used,
      outletMaxSeats: max,
      newTableSeats: newTableSeats,
    )) {
      return loc.table_seats_exceed_remaining(
        remainingOutletSeats(used, max),
        max,
      );
    }
    return null;
  }

  int get defaultSeatsForNewTable {
    final remaining = remainingSeats;
    if (remaining <= 0) return defaultTableSeats;
    return remaining < defaultTableSeats ? remaining : defaultTableSeats;
  }

  String get outletSeatingCapacityLabel =>
      seatingCapacityDisplayLabel(appPref.selectedOutlet?.seatingCapacity);

  int get nextSuggestedTableNumber {
    final limit = seatingCapacityLimit;
    if (limit <= 0) return 1;

    final usedNumbers = <int>{};
    for (final tws in tables) {
      final normalized = _normalizeTableNumber(tws.table.tableNumber);
      final numeric = int.tryParse(normalized);
      if (numeric != null && numeric > 0) {
        usedNumbers.add(numeric);
      }
    }

    for (var i = 1; i <= limit; i++) {
      if (!usedNumbers.contains(i)) return i;
    }
    return limit + 1;
  }

  @override
  void onInit() {
    super.onInit();
    reservationFilterDate.value = _todayDateString();
    loadTables();
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadTables() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _refreshOutletSeatingFromApi();

      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) {
        tables.clear();
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
              .where((t) => !t.isMergedSecondary)
              .toList();
          appPref.setCachedOutletTables(outletId, response.data);
        }
      } catch (_) {
        final loc = AppLocalizations.of(Get.context!)!;
        errorMessage.value = loc.unable_to_load_tables_from_server;
      }

      if (tableList.isEmpty) {
        final cached = appPref.getCachedOutletTables(outletId);
        if (cached != null && cached.isNotEmpty) {
          tableList = cached
              .map((e) => TableModel.fromTableData(e))
              .where((t) => !t.isMergedSecondary)
              .toList();
          errorMessage.value = '';
          debugPrint('📴 Loaded ${tableList.length} tables from offline cache');
        } else if (errorMessage.value.isEmpty) {
          errorMessage.value = '';
        }
      }

      await _loadReservations(outletId);

      await _trySyncOrdersForOutlet();

      List<OrderModel> orders = <OrderModel>[];
      try {
        orders = await db.getAllOrders(outletId: outletId);
      } catch (_) {
        final loc = AppLocalizations.of(Get.context!)!;
        errorMessage.value = loc.unable_to_load_local_orders;
      }

      tables.value = tableList.map((table) {
        final tableOrders = orders
            .where((o) => _matchesTable(o, table))
            .toList(growable: false);
        final order = _findCurrentOrderForTable(orders, table);
        final reservation = _findUpcomingReservationForTable(table);
        final status = _resolveStatus(
          order: order,
          table: table,
          reservation: reservation,
          hasLocalHistory: tableOrders.isNotEmpty,
        );

        return TableWithStatus(
          table: table,
          status: status,
          currentOrder: order,
          upcomingReservation: reservation,
        );
      }).toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshOutletSeatingFromApi() async {
    if (Get.isRegistered<HomeScreenController>()) {
      await Get.find<HomeScreenController>().getUserDetails();
    }
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;
    final updated = appPref.allOutlets.firstWhereOrNull(
      (o) => o.id == outletId,
    );
    if (updated != null) appPref.selectedOutlet = updated;
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

  TableReservationModel? _findUpcomingReservationForTable(TableModel table) {
    final today = _todayDateString();
    final matches = reservations
        .where((r) => r.isActive && r.tableId == table.id)
        .where((r) => r.reservationDate.compareTo(today) >= 0)
        .toList(growable: false);
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final dateCmp = a.reservationDate.compareTo(b.reservationDate);
      if (dateCmp != 0) return dateCmp;
      return a.reservationTime.compareTo(b.reservationTime);
    });
    return matches.first;
  }

  Future<void> _loadReservations(String outletId) async {
    try {
      final response = await callApi(
        apiClient.getTableReservations(
          outletId,
          date: reservationFilterDate.value.isEmpty
              ? null
              : reservationFilterDate.value,
        ),
        showLoader: false,
      );
      if (response?['status'] == 'success') {
        final data = (response['data'] as List?) ?? const [];
        reservations.value = data
            .whereType<Map>()
            .map(
              (e) =>
                  TableReservationModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {
      reservations.clear();
    }
  }

  TableStatus _resolveStatus({
    OrderModel? order,
    required TableModel table,
    TableReservationModel? reservation,
    required bool hasLocalHistory,
  }) {
    if (order != null) {
      final orderStatus = order.status.trim().toLowerCase();
      if (orderStatus == 'billing') return TableStatus.billing;
      return TableStatus.occupied;
    }

    if (reservation != null) return TableStatus.reserved;

    return TableStatus.available;
  }

  List<TableWithStatus> get filteredTables {
    final query = searchQuery.value.trim().toLowerCase();
    return tables
        .where((tws) {
          final searchable = tws.table.hasMergedTables
              ? tws.table.combinedDisplayName.toLowerCase()
              : tws.table.displayName.toLowerCase();
          final matchesQuery = query.isEmpty || searchable.contains(query);

          final matchesFilter = switch (selectedFilter.value) {
            TableFilter.all => true,
            TableFilter.available => tws.status == TableStatus.available,
            TableFilter.reserved => tws.status == TableStatus.reserved,
            TableFilter.occupied =>
              tws.status == TableStatus.occupied ||
                  tws.status == TableStatus.billing,
            TableFilter.merged => tws.table.hasMergedTables,
          };

          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
  }

  int get mergedTableGroupsCount =>
      tables.where((t) => t.table.hasMergedTables).length;

  int get mergedSecondaryTablesCount => tables
      .where((t) => t.table.hasMergedTables)
      .fold<int>(0, (sum, t) => sum + t.table.mergedTableNumbers.length);

  void setSearchQuery(String value) => searchQuery.value = value;
  void setFilter(TableFilter filter) => selectedFilter.value = filter;

  bool get canAddMoreTables => remainingSeats >= 1;

  /// Shows an alert when outlet seating is full; otherwise opens the add-table dialog.
  void promptAddTable() {
    final loc = AppLocalizations.of(Get.context!)!;
    if (seatingCapacityLimit <= 0) {
      showError(description: loc.set_outlet_seating_capacity_first);
      return;
    }
    if (!canAddMoreTables) {
      showError(description: loc.outlet_seating_full(seatingCapacityLimit));
      return;
    }
    TableFormDialog.show(controller: this);
  }

  Future<int> createDefaultTablesForCapacity() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final limit = seatingCapacityLimit;
    if (limit <= 0) {
      showError(description: loc.set_outlet_seating_capacity_first);
      return 0;
    }
    if (tables.isNotEmpty) return 0;

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return 0;
    }

    var created = 0;
    var usedSeats = 0;
    var tableNumber = 1;
    while (usedSeats < limit) {
      final remaining = limit - usedSeats;
      final seats = remaining >= defaultTableSeats
          ? defaultTableSeats
          : remaining;
      if (seats < 1) break;

      final response = await callApi(
        apiClient.createTable({
          'outletId': outletId,
          'tableNumber': '$tableNumber',
          'seatingcapacity': seats,
          'status': 'available',
        }),
        showLoader: false,
      );
      if (response != null && response['status'] == 'success') {
        created++;
        usedSeats += seats;
        tableNumber++;
      } else {
        break;
      }
    }

    if (created > 0) {
      await loadTables();
      showSuccess(
        description: loc.tables_count_of_limit(totalUsedSeats, limit),
      );
    } else {
      showError(description: loc.failed_to_add_table);
    }
    return created;
  }

  Future<bool> addTable({
    required String tableNumber,
    required int seatingCapacity,
  }) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final input = tableNumber.trim();
    if (input.isEmpty) {
      showError(description: loc.please_enter_table_number);
      return false;
    }
    if (seatingCapacity < 1) {
      showError(description: loc.seating_capacity_min_one);
      return false;
    }

    final limit = seatingCapacityLimit;
    if (limit <= 0) {
      showError(description: loc.set_outlet_seating_capacity_first);
      return false;
    }

    final seatsError = _tableSeatsValidationError(seatingCapacity);
    if (seatsError != null) {
      showError(description: seatsError);
      return false;
    }

    if (!canAddMoreTables) {
      showError(description: loc.outlet_seating_full(limit));
      return false;
    }

    final normalizedInput = _normalizeTableNumber(input);
    final exists = tables.any(
      (t) => _normalizeTableNumber(t.table.tableNumber) == normalizedInput,
    );
    if (exists) {
      showError(description: loc.table_already_exists);
      return false;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return false;
    }

    final response = await callApi(
      apiClient.createTable({
        'outletId': outletId,
        'tableNumber': input,
        'seatingcapacity': seatingCapacity,
        'status': 'available',
      }),
    );

    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: loc.table_added_successfully);
      return true;
    }

    showError(description: response?['message'] ?? loc.failed_to_add_table);
    return false;
  }

  Future<bool> updateTable({
    required TableModel table,
    required String tableNumber,
    required int seatingCapacity,
  }) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final input = tableNumber.trim();
    if (input.isEmpty) {
      showError(description: loc.please_enter_table_number);
      return false;
    }
    if (seatingCapacity < 1) {
      showError(description: loc.seating_capacity_min_one);
      return false;
    }

    final seatsError = _tableSeatsValidationError(
      seatingCapacity,
      excludeTableSeats: table.seatingCapacity,
    );
    if (seatsError != null) {
      showError(description: seatsError);
      return false;
    }

    final normalizedInput = _normalizeTableNumber(input);
    final duplicate = tables.any(
      (t) =>
          t.table.id != table.id &&
          _normalizeTableNumber(t.table.tableNumber) == normalizedInput,
    );
    if (duplicate) {
      showError(description: loc.another_table_already_uses_number);
      return false;
    }

    final response = await callApi(
      apiClient.updateTable(table.id, {
        'tableNumber': input,
        'seatingcapacity': seatingCapacity,
      }),
    );

    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: loc.table_updated_successfully);
      return true;
    }

    showError(description: response?['message'] ?? loc.failed_to_update_table);
    return false;
  }

  Future<bool> deleteTable(TableWithStatus tws) async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (!tws.isAvailable) {
      showError(description: loc.only_available_tables_can_be_deleted);
      return false;
    }

    if (tws.currentOrder != null) {
      showError(description: loc.cannot_delete_table_with_active_order);
      return false;
    }

    final response = await callApi(apiClient.deleteTable(tws.table.id));
    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: loc.table_deleted_successfully);
      return true;
    }

    showError(description: response?['message'] ?? loc.failed_to_delete_table);
    return false;
  }

  Future<bool> resetAllTables() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return false;
    }

    final response = await callApi(apiClient.resetAllTable(outletId));
    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: loc.all_tables_reset_successfully);
      return true;
    }

    showError(
      description: response?['message'] ?? loc.failed_to_reset_all_tables,
    );
    return false;
  }

  bool isMergeEligible(TableWithStatus tws) {
    if (tws.table.isMergedSecondary) return false;
    return true;
  }

  bool isSecondaryMergeEligible(TableWithStatus tws, String? primaryId) {
    if (primaryId == null || tws.table.id == primaryId) return false;
    if (tws.table.isMergedSecondary) return false;
    if (tws.table.hasMergedTables) return false;
    return true;
  }

  int effectiveSeatingCapacity(TableModel table) {
    var total = table.seatingCapacity;
    for (final tws in tables) {
      if (tws.table.mergedIntoTableId == table.id) {
        total += tws.table.seatingCapacity;
      }
    }
    return total;
  }

  List<TableWithStatus> reserveMergeCandidates(TableModel primary) {
    return tables
        .where(
          (tws) =>
              tws.table.id != primary.id &&
              tws.table.mergedIntoTableId != primary.id &&
              isSecondaryMergeEligible(tws, primary.id) &&
              tws.isAvailable &&
              tws.currentOrder == null,
        )
        .toList(growable: false);
  }

  int maxCombinablePartySize(TableModel primary) {
    var total = effectiveSeatingCapacity(primary);
    for (final tws in reserveMergeCandidates(primary)) {
      total += tws.table.seatingCapacity;
    }
    return total;
  }

  List<TableWithStatus> tablesFittingParty(
    int partySize, {
    String? excludeTableId,
  }) {
    return tables
        .where(
          (tws) =>
              !tws.table.isMergedSecondary &&
              tws.table.id != excludeTableId &&
              tws.isAvailable &&
              tws.currentOrder == null &&
              effectiveSeatingCapacity(tws.table) >= partySize,
        )
        .toList(growable: false);
  }

  String mergeTableSubtitle(TableWithStatus tws, AppLocalizations loc) {
    if (tws.currentOrder?.billNumber != null) {
      return loc.home_bill_number(tws.currentOrder!.billNumber.toString());
    }
    if (tws.table.hasMergedTables && tws.status == TableStatus.reserved) {
      final reservation = tws.upcomingReservation;
      if (reservation != null) {
        return loc.reserved_by(
          reservation.customerName,
          reservation.reservationTime,
        );
      }
      return loc.table_status_reserved;
    }
    if (tws.table.hasMergedTables && tws.status != TableStatus.reserved) {
      return loc.table_merged_with_others;
    }
    switch (tws.status) {
      case TableStatus.reserved:
        return loc.table_status_reserved;
      case TableStatus.occupied:
        return loc.home_occupied;
      case TableStatus.billing:
        return loc.home_billing;
      default:
        return loc.table_status_available;
    }
  }

  Future<void> onTableTap(TableWithStatus tws) async {
    if (tws.isReserved && tws.currentOrder == null) {
      await _showReservationActionsDialog(tws);
      return;
    }

    if (tws.isAvailable) {
      await Modular.to.pushNamed(
        HomeMainRoutes.createOrder,
        arguments: {
          'orderFrom': 'Dine In',
          'tableNumber': tws.table.hasMergedTables
              ? tws.table.combinedDisplayName
              : tws.table.displayName,
          'fromTables': true,
        },
      );
      await loadTables();
      return;
    }

    if (tws.currentOrder != null) {
      await Modular.to.pushNamed(
        HomeMainRoutes.createOrder,
        arguments: {
          'order': tws.currentOrder,
          'isEdit': true,
          'fromTables': true,
        },
      );
      await loadTables();
      return;
    }

    // Table marked Occupied/Billing but we don't have an active local order.
    // This happens when orders aren't synced to local DB yet (common on fresh
    // launch, multi-device usage, or after reconnect). Try a quick sync, then
    // fall back to allowing a new order instead of blocking the user.
    final synced = await _trySyncOrdersForOutlet();
    if (synced) {
      await loadTables();
      final updated = tables.firstWhereOrNull(
        (t) => t.table.id == tws.table.id,
      );
      if (updated?.currentOrder != null) {
        await Modular.to.pushNamed(
          HomeMainRoutes.createOrder,
          arguments: {
            'order': updated!.currentOrder,
            'isEdit': true,
            'fromTables': true,
          },
        );
        await loadTables();
        return;
      }
    }

    await Modular.to.pushNamed(
      HomeMainRoutes.createOrder,
      arguments: {
        'orderFrom': 'Dine In',
        'tableNumber': tws.table.displayName,
        'fromTables': true,
      },
    );
    await loadTables();
  }

  Future<void> openMergeTablesDialog() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final eligible = tables.where(isMergeEligible).toList(growable: false);
    if (eligible.length < 2) {
      showError(description: loc.no_tables_to_merge);
      return;
    }
    await MergeTablesDialog.show(controller: this, initialEligible: eligible);
  }

  Future<bool> executeMerge(String primaryId, List<String> secondaryIds) async {
    return _executeMerge(primaryId, secondaryIds);
  }

  Future<bool> _executeMerge(
    String primaryId,
    List<String> secondaryIds, {
    bool notify = true,
  }) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return false;
    }

    final response = await callApi(
      apiClient.mergeTables({
        'outletId': outletId,
        'primaryTableId': primaryId,
        'secondaryTableIds': secondaryIds,
      }),
    );

    if (response != null && response['status'] == 'success') {
      await loadTables();
      if (notify) {
        showSuccess(description: loc.merge_tables_success);
      }
      return true;
    }

    showError(description: response?['message'] ?? loc.merge_tables_failed);
    return false;
  }

  Future<bool> unmergeTable(TableModel table, {bool notify = true}) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return false;
    }

    final response = await callApi(apiClient.unmergeTables(table.id, outletId));

    if (response != null && response['status'] == 'success') {
      await loadTables();
      if (notify) {
        showSuccess(description: loc.unmerge_tables_success);
      }
      return true;
    }

    showError(description: response?['message'] ?? loc.unmerge_tables_failed);
    return false;
  }

  List<TableModel> mergedChildModels(String primaryId) {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return [];
    final cached = appPref.getCachedOutletTables(outletId);
    if (cached == null || cached.isEmpty) return [];
    return cached
        .map((e) => TableModel.fromTableData(e))
        .where((t) => t.mergedIntoTableId == primaryId)
        .toList(growable: false);
  }

  List<String> mergedChildIds(String primaryId) => mergedChildModels(primaryId)
      .map((t) => t.id)
      .toList(growable: false);

  List<TableWithStatus> mergeEditCandidates(TableModel primary) {
    final childModels = mergedChildModels(primary.id);
    final childIds = childModels.map((t) => t.id).toSet();
    final candidates = <TableWithStatus>[];

    for (final child in childModels) {
      final existing = tables.firstWhereOrNull((t) => t.table.id == child.id);
      candidates.add(
        existing ??
            TableWithStatus(table: child, status: TableStatus.available),
      );
    }

    for (final tws in tables) {
      if (tws.table.id == primary.id) continue;
      if (childIds.contains(tws.table.id)) continue;
      if (isSecondaryMergeEligible(tws, primary.id)) {
        candidates.add(tws);
      }
    }

    return candidates;
  }

  Future<void> openEditMergedTablesDialog(TableWithStatus tws) async {
    if (!tws.table.hasMergedTables) return;
    await MergeTablesDialog.showEdit(
      controller: this,
      mergedPrimary: tws,
    );
  }

  Future<bool> updateMergedTables(
    String primaryId,
    List<String> newSecondaryIds,
  ) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final currentIds = mergedChildIds(primaryId);
    final newIds = newSecondaryIds.toList(growable: false);

    if (currentIds.length == newIds.length &&
        currentIds.every(newIds.contains) &&
        newIds.every(currentIds.contains)) {
      return true;
    }

    final primary = tables.firstWhereOrNull((t) => t.table.id == primaryId);
    if (primary == null) return false;

    if (currentIds.isNotEmpty) {
      final unmerged = await unmergeTable(primary.table, notify: false);
      if (!unmerged) return false;
    }

    if (newIds.isEmpty) {
      showSuccess(description: loc.unmerge_tables_success);
      return true;
    }

    final merged = await _executeMerge(primaryId, newIds, notify: false);
    if (merged) {
      showSuccess(description: loc.merged_tables_updated_success);
    }
    return merged;
  }

  Future<bool> createReservation({
    required TableModel table,
    required String customerName,
    String? customerPhone,
    required int partySize,
    required String reservationDate,
    required String reservationTime,
    String? notes,
  }) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return false;
    }

    final response = await callApi(
      apiClient.createTableReservation({
        'outletId': outletId,
        'tableId': table.id,
        'customerName': customerName.trim(),
        'customerPhone': customerPhone?.trim(),
        'partySize': partySize,
        'reservationDate': reservationDate,
        'reservationTime': reservationTime,
        'notes': notes?.trim(),
        'source': 'pos',
      }),
    );

    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: loc.reservation_created_successfully);
      return true;
    }

    showError(
      description: response?['message'] ?? loc.failed_to_create_reservation,
    );
    return false;
  }

  Future<bool> cancelReservation(TableReservationModel reservation) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final response = await callApi(
      apiClient.cancelTableReservation(reservation.id),
    );
    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: loc.reservation_cancelled_successfully);
      return true;
    }
    showError(
      description: response?['message'] ?? loc.failed_to_create_reservation,
    );
    return false;
  }

  Future<bool> seatReservation(TableReservationModel reservation) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final response = await callApi(
      apiClient.seatTableReservation(reservation.id),
    );
    if (response != null && response['status'] == 'success') {
      await loadTables();
      showSuccess(description: loc.reservation_seated_successfully);
      return true;
    }
    showError(
      description: response?['message'] ?? loc.failed_to_create_reservation,
    );
    return false;
  }

  Future<void> _showReservationActionsDialog(TableWithStatus tws) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final reservation = tws.upcomingReservation;
    if (reservation == null) return;

    final context = Get.context!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isWhatsApp = reservation.source.toLowerCase() == 'whatsapp';

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.table_restaurant_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tws.table.displayName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            loc.reservation_for_table(tws.table.displayName),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWhatsApp)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF25D366).withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF25D366,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Assets.svg.whatsapp.svg(
                                width: 20,
                                height: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF25D366),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ── Guest Info ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + name row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            reservation.customerName.isNotEmpty
                                ? reservation.customerName[0].toUpperCase()
                                : '?',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reservation.customerName,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (reservation.customerPhone != null &&
                                  reservation.customerPhone!.isNotEmpty)
                                Text(
                                  reservation.customerPhone!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withOpacity(0.12),
                    ),
                    const SizedBox(height: 14),

                    // Info chips row
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: reservation.reservationDate,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: reservation.reservationTime,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.people_outline_rounded,
                          label: '${reservation.partySize}',
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),

              // ── Actions ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (Get.isDialogOpen == true) Get.back();
                          await cancelReservation(reservation);
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: Text(loc.cancel_reservation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(
                            color: colorScheme.error.withOpacity(0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (Get.isDialogOpen == true) Get.back();
                          await seatReservation(reservation);
                          await Modular.to.pushNamed(
                            HomeMainRoutes.createOrder,
                            arguments: {
                              'orderFrom': 'Dine In',
                              'tableNumber': tws.table.displayName,
                              'fromTables': true,
                            },
                          );
                          await loadTables();
                        },
                        icon: const Icon(Icons.chair_outlined, size: 16),
                        label: Text(loc.seat_guest),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
    );
  }

  Future<void> refresh() => loadTables();

  Future<String?> _ensureTableMenuUrl(TableModel table) async {
    var url = TableQrPrintService.menuUrlForTable(table);
    if (url.isNotEmpty) return url;

    try {
      final response = await callApi(
        apiClient.generateTableQr(table.id),
        showLoader: true,
      );
      final data = response?['data'] as Map<String, dynamic>?;
      final token =
          (data?['qrToken'] as String?)?.trim() ?? table.qrToken?.trim();
      if (token != null && token.isNotEmpty) {
        url = QrMenuUrlConfig.buildTableMenuUrl(token, pref: appPref);
      }
      if (url.isNotEmpty) {
        await loadTables();
      }
      return url.isNotEmpty ? url : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> showTableQr(TableModel table) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final context = Get.context;
    if (context == null || !context.mounted) return;

    final url = await _ensureTableMenuUrl(table);
    if (url == null || url.isEmpty) {
      showError(description: loc.could_not_generate_qr_for_table);
      return;
    }

    if (!context.mounted) return;
    final businessName = appPref.selectedOutlet?.businessName ?? 'Restaurant';
    try {
      await TableQrService.showTableQr(
        context: context,
        businessName: businessName,
        table: table,
        menuUrl: url,
        onPrint: () => printTableQr(table),
      );
    } catch (e) {
      showError(description: loc.print_failed_with_error('$e'));
    }
  }

  Future<void> generateAllQrsAndShow() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final context = Get.context;
    if (context == null || !context.mounted) return;

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    try {
      await callApi(apiClient.generateAllTableQr(outletId), showLoader: true);
      await loadTables();

      if (!context.mounted) return;
      final businessName = appPref.selectedOutlet?.businessName ?? 'Restaurant';
      final tableModels = tables.map((t) => t.table).toList();
      await TableQrService.showAllTableQrs(
        context: context,
        businessName: businessName,
        tables: tableModels,
        onPrintAll: () => generateAllQrsAndPrint(skipRegenerate: true),
        onPrintTable: printTableQr,
      );
    } catch (e) {
      showError(description: loc.failed_to_generate_print_qr('$e'));
    }
  }

  Future<void> printTableQr(TableModel table) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final url = await _ensureTableMenuUrl(table);
    if (url == null || url.isEmpty) {
      showError(description: loc.could_not_generate_qr_for_table);
      return;
    }
    final businessName = appPref.selectedOutlet?.businessName ?? 'Restaurant';
    try {
      await TableQrPrintService.printTableQr(
        businessName: businessName,
        table: table,
        menuUrl: url,
      );
      showSuccess(description: loc.table_qr_printed_successfully);
    } catch (e) {
      showError(description: loc.print_failed_with_error('$e'));
      rethrow;
    }
  }

  Future<void> generateAllQrsAndPrint({bool skipRegenerate = false}) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    try {
      if (!skipRegenerate) {
        await callApi(apiClient.generateAllTableQr(outletId), showLoader: true);
        await loadTables();
      }

      final businessName = appPref.selectedOutlet?.businessName ?? 'Restaurant';
      final tableModels = tables.map((t) => t.table).toList();
      await TableQrPrintService.printAllTableQrs(
        businessName: businessName,
        tables: tableModels,
      );
      showSuccess(description: loc.all_table_qrs_printed_successfully);
    } catch (e) {
      showError(description: loc.failed_to_generate_print_qr('$e'));
      rethrow;
    }
  }

  Future<bool> _trySyncOrdersForOutlet() async {
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.ordersApiUserId;
    if (outletId == null || userId == null) return false;

    try {
      final response = await callApi(
        apiClient.getOrders(
          userId,
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

      final orders = response?.data ?? <OrderModel>[];
      if (orders.isEmpty) return false;

      await db.insertOrders(orders, outletId, isSyncedFromApi: true);
      return true;
    } catch (_) {
      return false;
    }
  }

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
    try {
      await db.updateOrderStatus(
        orderId: order.id,
        status: 'Closed',
        paymentStatus: 'Completed',
      );
    } catch (e) {
      debugPrint('Failed to close order locally: $e');
    }

    await loadTables();
  }
}

// ── Reusable info chip ────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 5),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}
