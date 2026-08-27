import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Tables/merge_tables_dialog.dart';
import 'package:billkaro/app/modules/Tables/table_form_dialog.dart';
import 'package:billkaro/app/modules/Tables/table_qr_print_service.dart';
import 'package:billkaro/app/modules/Tables/table_qr_service.dart';
import 'package:billkaro/app/Database/app_database.dart' as dbs;
import 'package:billkaro/utils/offline/offline_table_loader.dart';
import 'package:billkaro/utils/outlet_seating.dart';
import 'package:billkaro/utils/qr_menu_url_config.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/tables/table_reservation_model.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:billkaro/utils/staff_access.dart';

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
  final RxList<TableSectionModel> sections = <TableSectionModel>[].obs;
  final RxList<TableReservationModel> reservations =
      <TableReservationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<TableFilter> selectedFilter = TableFilter.all.obs;

  /// `null` = all sections. Otherwise matches [TableModel.section] (`''` = General).
  final RxnString selectedSection = RxnString();
  final RxString errorMessage = ''.obs;
  final RxString reservationFilterDate = ''.obs;
  int _loadGeneration = 0;

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
    final generation = ++_loadGeneration;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      tables.clear();
      sections.clear();
      isLoading.value = false;
      return;
    }

    errorMessage.value = '';
    if (tables.isEmpty) isLoading.value = true;

    try {
      _applyCachedSections(outletId);
      final cachedTables = OfflineTableLoader.loadCached(
        appPref,
        outletId,
        excludeMergedSecondary: true,
      );
      var orders = await _localOrders(outletId);
      if (cachedTables.isNotEmpty) {
        _assignTables(cachedTables, orders);
        isLoading.value = false;
        debugPrint('📴 Showing ${cachedTables.length} cached tables');
      }

      final online = await NetworkUtils.hasInternetConnection();
      if (!online || generation != _loadGeneration) return;

      await _refreshOutletSeatingFromApi();
      if (generation != _loadGeneration) return;

      var tableList = List<TableModel>.from(cachedTables);
      try {
        final response = await callApi(
          apiClient.getOutletTables(outletId),
          showLoader: false,
        );
        if (generation != _loadGeneration) return;
        if (response?.status == 'success') {
          tableList = response!.data
              .map((e) => TableModel.fromTableData(e))
              .where((t) => !t.isMergedSecondary)
              .toList();
          appPref.setCachedOutletTables(outletId, response.data);
          errorMessage.value = '';
        }
      } catch (e) {
        debugPrint('loadTables API error: $e');
        if (tableList.isEmpty) {
          errorMessage.value = _unableToLoadTablesMessage();
        }
      }

      await _loadSections(outletId);
      await _loadReservations(outletId);
      await _trySyncOrdersForOutlet();
      if (generation != _loadGeneration) return;

      orders = await _localOrders(outletId);
      _assignTables(tableList, orders);
    } catch (e) {
      debugPrint('loadTables error: $e');
    } finally {
      if (generation == _loadGeneration) {
        isLoading.value = false;
      }
    }
  }

  void _assignTables(List<TableModel> tableList, List<OrderModel> orders) {
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
  }

  Future<List<OrderModel>> _localOrders(String outletId) async {
    try {
      return await db.getAllOrders(outletId: outletId);
    } catch (e) {
      debugPrint('loadTables orders error: $e');
      return const [];
    }
  }

  void _applyCachedSections(String outletId) {
    final cached = appPref.getCachedOutletTableSections(outletId);
    if (cached == null || cached.isEmpty) return;
    sections.assignAll(cached);
  }

  String _unableToLoadTablesMessage() {
    final context = Get.context;
    if (context == null) return 'Unable to load tables';
    return AppLocalizations.of(context)?.unable_to_load_tables_from_server ??
        'Unable to load tables';
  }

  Future<void> _refreshOutletSeatingFromApi() async {
    if (!await NetworkUtils.hasInternetConnection()) return;
    try {
      if (Get.isRegistered<HomeScreenController>()) {
        await Get.find<HomeScreenController>().getUserDetails();
      }
    } catch (e) {
      debugPrint('refreshOutletSeating error: $e');
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

  bool _isActiveOrder(OrderModel order) {
    final status = order.status.trim().toLowerCase();
    return status != 'closed' && status != 'deleted';
  }

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

  bool _reservationMatchesTable(
    TableReservationModel reservation,
    TableModel table,
  ) {
    if (reservation.tableId.isNotEmpty && reservation.tableId == table.id) {
      return true;
    }
    final reservationTable = reservation.tableNumber?.trim() ?? '';
    if (reservationTable.isEmpty) return false;
    return _tableKeys(table).contains(_normalizeTableNumber(reservationTable));
  }

  List<TableReservationModel> _activeReservationsForTable(TableModel table) {
    final today = _todayDateString();
    final matches = reservations
        .where((r) => r.isActive && _reservationMatchesTable(r, table))
        .where((r) => r.reservationDate.compareTo(today) >= 0)
        .toList(growable: true);
    matches.sort((a, b) {
      final dateCmp = a.reservationDate.compareTo(b.reservationDate);
      if (dateCmp != 0) return dateCmp;
      return a.reservationTime.compareTo(b.reservationTime);
    });
    return matches;
  }

  /// Next active booking for this table (today or later) — used for UI details.
  TableReservationModel? _findUpcomingReservationForTable(TableModel table) {
    final items = _activeReservationsForTable(table);
    return items.isEmpty ? null : items.first;
  }

  /// Used by reserve dialog to avoid double-booking the same slot.
  TableReservationModel? findReservationConflict({
    required TableModel table,
    required String reservationDate,
    required String reservationTime,
  }) {
    final date = TableReservationModel.asDateOnly(reservationDate);
    final time = TableReservationModel.asTimeHm(reservationTime);
    return _activeReservationsForTable(table).firstWhereOrNull(
      (r) => r.reservationDate == date && r.reservationTime == time,
    );
  }

  List<TableReservationModel> reservationsForTable(TableModel table) =>
      _activeReservationsForTable(table);

  /// Upcoming active reservations for the reservations list dialog.
  List<TableReservationModel> get upcomingReservations {
    final today = _todayDateString();
    final items = reservations
        .where((r) => r.isActive && r.reservationDate.compareTo(today) >= 0)
        .toList(growable: true);
    items.sort((a, b) {
      final dateCmp = a.reservationDate.compareTo(b.reservationDate);
      if (dateCmp != 0) return dateCmp;
      return a.reservationTime.compareTo(b.reservationTime);
    });
    return items;
  }

  Future<void> _loadReservations(String outletId) async {
    if (!await NetworkUtils.hasInternetConnection()) return;

    try {
      // Load all outlet reservations (no date filter). Filtering only by today
      // hid future bookings and made reserved tables look available.
      final response = await callApi(
        apiClient.getTableReservations(outletId),
        showLoader: false,
      );
      if (response?['status'] == 'success') {
        final data = (response['data'] as List?) ?? const [];
        final today = _todayDateString();
        final parsed = <TableReservationModel>[];
        for (final item in data) {
          if (item is! Map) continue;
          try {
            final reservation = TableReservationModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (reservation.id.isEmpty || reservation.tableId.isEmpty) continue;
            if (!reservation.isActive) continue;
            if (reservation.reservationDate.compareTo(today) < 0) continue;
            parsed.add(reservation);
          } catch (e) {
            debugPrint('Skip invalid reservation payload: $e');
          }
        }
        reservations.value = parsed;
      }
    } catch (_) {}
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

    // Only mark reserved on the floor for today's bookings.
    // Future bookings stay orderable today, but still appear in reserve UI.
    if (reservation != null &&
        reservation.reservationDate == _todayDateString()) {
      return TableStatus.reserved;
    }

    return TableStatus.available;
  }

  List<TableWithStatus> get filteredTables {
    final query = searchQuery.value.trim().toLowerCase();
    final sectionFilter = selectedSection.value;
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

          final matchesSection = sectionFilter == null
              ? true
              : _normalizeSectionKey(tws.table.section) ==
                    _normalizeSectionKey(sectionFilter);

          return matchesQuery && matchesFilter && matchesSection;
        })
        .toList(growable: false);
  }

  /// Section names for filters (managed + any used on tables). General first.
  List<String> get availableSections {
    final named = <String>{};
    for (final s in sections) {
      final n = s.name.trim();
      if (n.isNotEmpty) named.add(n);
    }
    for (final tws in tables) {
      final n = tws.table.section.trim();
      if (n.isNotEmpty) named.add(n);
    }
    final sorted = named.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final hasGeneral = tables.any((t) => t.table.section.trim().isEmpty);
    return [if (hasGeneral) '', ...sorted];
  }

  /// Sections created for this outlet — used in the add/edit table dialog.
  List<String> get sectionSuggestions {
    return sections
        .map((s) => s.name.trim())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Groups [filteredTables] by section key for the grid UI.
  Map<String, List<TableWithStatus>> get filteredTablesBySection {
    // Always read sections so Obx rebuilds when a section is added/removed.
    final managedSections = sections.toList(growable: false);
    final map = <String, List<TableWithStatus>>{};
    for (final tws in filteredTables) {
      final key = tws.table.section.trim();
      map.putIfAbsent(key, () => []).add(tws);
    }

    // Show managed sections with no tables when browsing all sections.
    final sectionFilter = selectedSection.value;
    if (sectionFilter == null) {
      for (final s in managedSections) {
        final key = s.name.trim();
        if (key.isNotEmpty) map.putIfAbsent(key, () => []);
      }
    } else if (sectionFilter.trim().isNotEmpty) {
      map.putIfAbsent(sectionFilter.trim(), () => []);
    }

    final orderedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty && b.isNotEmpty) return -1;
        if (a.isNotEmpty && b.isEmpty) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return {for (final k in orderedKeys) k: map[k]!};
  }

  String sectionDisplayName(String section, AppLocalizations loc) {
    final trimmed = section.trim();
    return trimmed.isEmpty ? loc.table_section_general : trimmed;
  }

  static String _normalizeSectionKey(String value) =>
      value.trim().toLowerCase();

  int get mergedTableGroupsCount =>
      tables.where((t) => t.table.hasMergedTables).length;

  int get mergedSecondaryTablesCount => tables
      .where((t) => t.table.hasMergedTables)
      .fold<int>(0, (sum, t) => sum + t.table.mergedTableNumbers.length);

  void setSearchQuery(String value) => searchQuery.value = value;
  void setFilter(TableFilter filter) => selectedFilter.value = filter;
  void setSectionFilter(String? section) => selectedSection.value = section;

  bool get canAddMoreTables => remainingSeats >= 1;

  Future<void> _loadSections(String outletId) async {
    _applyCachedSections(outletId);
    if (!await NetworkUtils.hasInternetConnection()) return;

    try {
      final response = await callApi(
        apiClient.getOutletTableSections(outletId),
        showLoader: false,
      );
      if (response is Map && response['status'] == 'success') {
        final raw = response['data'];
        if (raw is List) {
          final parsed = raw
              .whereType<Map>()
              .map(
                (e) =>
                    TableSectionModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .where((s) => s.name.isNotEmpty)
              .toList();
          sections.assignAll(parsed);
          appPref.setCachedOutletTableSections(outletId, parsed);
        }
      }
    } catch (_) {}
  }

  void promptAddSection() {
    if (!StaffAccess.ensure(StaffAccess.canCreateTables)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    final nameController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(loc.add_section),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: loc.section_name,
            hintText: loc.section_name_hint,
          ),
          onSubmitted: (_) async {
            final ok = await addSection(nameController.text);
            if (ok && Get.isDialogOpen == true) Get.back();
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
          FilledButton(
            onPressed: () async {
              final ok = await addSection(nameController.text);
              if (ok && Get.isDialogOpen == true) Get.back();
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  Future<bool> addSection(String name) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final input = name.trim();
    if (input.isEmpty) {
      showError(description: loc.please_enter_section_name);
      return false;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return false;
    }

    final exists = sections.any(
      (s) => s.name.trim().toLowerCase() == input.toLowerCase(),
    );
    if (exists) {
      showError(description: loc.section_already_exists);
      return false;
    }

    final response = await callApi(
      apiClient.createOutletTableSection({'outletId': outletId, 'name': input}),
    );

    if (response is Map && response['status'] == 'success') {
      await _loadSections(outletId);
      showSuccess(description: loc.section_added_successfully);
      return true;
    }

    showError(
      description: response is Map
          ? (response['message']?.toString() ?? loc.failed_to_add_section)
          : loc.failed_to_add_section,
    );
    return false;
  }

  TableSectionModel? managedSectionFor(String name) {
    final key = _normalizeSectionKey(name);
    if (key.isEmpty) return null;
    for (final section in sections.toList(growable: false)) {
      if (_normalizeSectionKey(section.name) != key) continue;
      if (section.id.trim().isEmpty) continue;
      return section;
    }
    return null;
  }

  int tableCountInSection(String name) {
    final key = _normalizeSectionKey(name);
    return tables
        .where((tws) => _normalizeSectionKey(tws.table.section) == key)
        .length;
  }

  bool canDeleteManagedSection(String name) =>
      StaffAccess.canDeleteTables && managedSectionFor(name) != null;

  Future<void> promptDeleteSection(String name) async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteTables)) return;

    final loc = AppLocalizations.of(Get.context!)!;
    final section = managedSectionFor(name);
    if (section == null) {
      showError(description: loc.failed_to_delete_section);
      return;
    }

    final assigned = tableCountInSection(section.name);
    if (assigned > 0) {
      showError(
        description: loc.delete_section_has_tables(section.name, assigned),
      );
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.delete_section),
        content: Text(loc.delete_section_confirm(section.name)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(loc.delete),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed == true) {
      await deleteSection(section);
    }
  }

  Future<bool> deleteSection(TableSectionModel section) async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteTables)) return false;

    final loc = AppLocalizations.of(Get.context!)!;
    final id = section.id.trim();
    if (id.isEmpty) {
      showError(description: loc.failed_to_delete_section);
      return false;
    }

    final assigned = tableCountInSection(section.name);
    if (assigned > 0) {
      showError(
        description: loc.delete_section_has_tables(section.name, assigned),
      );
      return false;
    }

    final response = await callApi(apiClient.deleteOutletTableSection(id));
    final ok =
        response is Map && response['status']?.toString() == 'success';

    if (ok) {
      final key = _normalizeSectionKey(section.name);
      sections.removeWhere((s) => _normalizeSectionKey(s.name) == key);
      sections.refresh();

      final selected = selectedSection.value;
      if (selected != null && _normalizeSectionKey(selected) == key) {
        selectedSection.value = null;
      }

      showSuccess(description: loc.section_deleted_successfully);
      return true;
    }

    showError(
      description: response is Map
          ? (response['message']?.toString() ?? loc.failed_to_delete_section)
          : loc.failed_to_delete_section,
    );
    return false;
  }

  /// Shows an alert when outlet seating is full; otherwise opens the add-table dialog.
  void promptAddTable() {
    if (!StaffAccess.ensure(StaffAccess.canCreateTables)) return;
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
    String section = '',
  }) async {
    if (!StaffAccess.ensure(StaffAccess.canCreateTables)) return false;
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
        'section': section.trim(),
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
    String? section,
  }) async {
    if (!StaffAccess.ensure(StaffAccess.canUpdateTables)) return false;
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
        'section': (section ?? table.section).trim(),
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
    if (!StaffAccess.ensure(StaffAccess.canDeleteTables)) return false;
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
    if (!StaffAccess.ensure(StaffAccess.canUpdateTables)) return false;
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
      if (!StaffAccess.ensure(StaffAccess.canShowCreateOrder)) return;
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
      if (!StaffAccess.ensure(StaffAccess.canShowEditOrder)) return;
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
        if (!StaffAccess.ensure(StaffAccess.canShowEditOrder)) return;
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

    if (!StaffAccess.ensure(StaffAccess.canShowCreateOrder)) return;
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
    if (!StaffAccess.ensure(StaffAccess.canUpdateTables)) return false;
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
    if (!StaffAccess.ensure(StaffAccess.canUpdateTables)) return false;
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

  List<String> mergedChildIds(String primaryId) =>
      mergedChildModels(primaryId).map((t) => t.id).toList(growable: false);

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
    await MergeTablesDialog.showEdit(controller: this, mergedPrimary: tws);
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

    final cleanName = customerName.trim();
    final cleanPhone = customerPhone?.trim() ?? '';
    final cleanNotes = notes?.trim() ?? '';
    final cleanDate = TableReservationModel.asDateOnly(reservationDate);
    final cleanTime = TableReservationModel.asTimeHm(reservationTime);

    if (cleanName.isEmpty) {
      showError(description: loc.reservation_name_required);
      return false;
    }

    final conflict = findReservationConflict(
      table: table,
      reservationDate: cleanDate,
      reservationTime: cleanTime,
    );
    if (conflict != null) {
      showError(
        description:
            'Table ${table.displayName} is already reserved at $cleanTime on $cleanDate'
            '${conflict.customerName.isNotEmpty ? ' by ${conflict.customerName}' : ''}',
      );
      return false;
    }

    final payload = <String, dynamic>{
      'outletId': outletId,
      'tableId': table.id,
      'customerName': cleanName,
      'partySize': partySize,
      'reservationDate': cleanDate,
      'reservationTime': cleanTime,
      'source': 'pos',
    };
    if (cleanPhone.isNotEmpty) {
      payload['customerPhone'] = cleanPhone;
    }
    if (cleanNotes.isNotEmpty) {
      payload['notes'] = cleanNotes;
    }

    final response = await callApi(
      apiClient.createTableReservation(payload),
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
                          if (!StaffAccess.ensure(
                            StaffAccess.canShowCreateOrder,
                          )) {
                            return;
                          }
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
    if (!await NetworkUtils.hasInternetConnection()) return false;
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
