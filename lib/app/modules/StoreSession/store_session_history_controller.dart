import 'package:billkaro/app/Widgets/app_date_picker.dart';
import 'package:billkaro/app/services/Modals/store_session/store_session_model.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

class StaffFilterOption {
  const StaffFilterOption({required this.id, required this.name});

  final String id;
  final String name; 
}

class StoreSessionHistoryController extends BaseController {
  final RxList<OutletDaySession> sessions = <OutletDaySession>[].obs;
  final RxList<OutletDaySession> _allSessions = <OutletDaySession>[].obs;
  final RxList<StaffFilterOption> staffFilterOptions =
      <StaffFilterOption>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingStaff = false.obs;
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  final RxString selectedTimePeriod = 'All'.obs;
  final RxString selectedStaffFilterId = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    selectedDateRange.value = null;
  }

  @override
  void onReady() {
    super.onReady();
    loadStaffOptions();
    loadHistory();
  }

  Future<void> loadStaffOptions() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      staffFilterOptions.clear();
      return;
    }

    isLoadingStaff.value = true;
    try {
      final options = <StaffFilterOption>[];

      final owner = appPref.user;
      final ownerId = owner?.id?.trim();
      final ownerName = owner?.firstName?.trim().isNotEmpty == true
          ? owner!.firstName!.trim()
          : owner?.email?.trim();
      if (ownerId != null &&
          ownerId.isNotEmpty &&
          ownerName != null &&
          ownerName.isNotEmpty) {
        options.add(StaffFilterOption(id: ownerId, name: ownerName));
      }

      final response = await callApi(
        apiClient.getStaffList(outletId),
        showLoader: false,
      );
      final staffRows = _extractStaffList(response);
      final seen = options.map((e) => e.id).toSet();

      for (final raw in staffRows) {
        if (!_isActiveStaff(raw)) continue;
        final id = _staffId(raw);
        final name = _staffName(raw);
        if (id.isEmpty || name.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        options.add(StaffFilterOption(id: id, name: name));
      }

      options.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      staffFilterOptions.assignAll(options);

      if (selectedStaffFilterId.value != 'all' &&
          !staffFilterOptions.any((o) => o.id == selectedStaffFilterId.value)) {
        selectedStaffFilterId.value = 'all';
        applyStaffFilter();
      }
    } finally {
      isLoadingStaff.value = false;
    }
  }

  Future<void> loadHistory({bool showLoader = true}) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      _allSessions.clear();
      sessions.clear();
      return;
    }

    isLoading.value = true;
    try {
      final range = selectedDateRange.value;
      final startDateStr = range != null
          ? DateFormat('yyyy-MM-dd').format(range.start)
          : null;
      final endDateStr = range != null
          ? DateFormat('yyyy-MM-dd').format(range.end)
          : null;

      final response = await callApi(
        apiClient.getDaySessionHistory(outletId, startDateStr, endDateStr),
        showLoader: showLoader,
      );
      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data is List) {
          _allSessions.assignAll(
            data
                .whereType<Map<String, dynamic>>()
                .map(OutletDaySession.fromJson)
                .toList(),
          );
        } else {
          _allSessions.clear();
        }
      }
      applyStaffFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void onStaffFilterChanged(String? staffId) {
    if (staffId == null) return;
    selectedStaffFilterId.value = staffId;
    applyStaffFilter();
  }

  void applyStaffFilter() {
    if (selectedStaffFilterId.value == 'all') {
      sessions.assignAll(_allSessions);
      return;
    }

    final staffId = selectedStaffFilterId.value;
    final selectedName = staffFilterOptions
        .firstWhereOrNull((o) => o.id == staffId)
        ?.name
        .trim()
        .toLowerCase();

    sessions.assignAll(
      _allSessions.where((session) {
        if (session.openedByUserId == staffId ||
            session.closedByUserId == staffId) {
          return true;
        }
        if (selectedName == null || selectedName.isEmpty) return false;
        final openedName = session.openedByName?.trim().toLowerCase();
        final closedName = session.closedByName?.trim().toLowerCase();
        return openedName == selectedName || closedName == selectedName;
      }),
    );
  }

  Future<void> filterByTimePeriod() async {
    if (selectedTimePeriod.value == 'Custom') {
      await selectCustomDateRange();
      return;
    }

    final now = DateTime.now();
    DateTimeRange? range;

    switch (selectedTimePeriod.value) {
      case 'All':
        range = null;
        break;
      case 'Today':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        range = DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
      case 'This Month':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
      case 'This Quarter':
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (currentQuarter - 1) * 3 + 1;
        range = DateTimeRange(
          start: DateTime(now.year, startMonth, 1),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
      case 'This Year':
        range = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
    }

    selectedDateRange.value = range;
    await loadHistory();
  }

  Future<void> selectCustomDateRange() async {
    final picked = await showAppDateRangePickerFromGet(
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange.value,
    );

    if (picked != null) {
      selectedDateRange.value = picked;
      selectedTimePeriod.value = 'Custom';
      await loadHistory();
    } else if (selectedTimePeriod.value == 'Custom' &&
        selectedDateRange.value == null) {
      selectedTimePeriod.value = 'Today';
      await filterByTimePeriod();
    }
  }

  String get formattedDateRange {
    final loc = AppLocalizations.of(Get.context!)!;
    if (selectedDateRange.value == null) return loc.select_date;
    final start = selectedDateRange.value!.start;
    final end = selectedDateRange.value!.end;
    return '${_formatDate(start)} ${loc.date_range_to_separator} ${_formatDate(end)}';
  }

  List<String> getLocalizedTimePeriods() {
    return const [
      'All',
      'Today',
      'This Week',
      'This Month',
      'This Quarter',
      'This Year',
      'Custom',
    ];
  }

  String getLocalizedTimePeriodLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'All':
        return loc.all;
      case 'Today':
        return loc.today;
      case 'This Week':
        return loc.this_week;
      case 'This Month':
        return loc.this_month;
      case 'This Quarter':
        return loc.this_quarter;
      case 'This Year':
        return loc.this_year;
      case 'Custom':
        return loc.custom;
      default:
        return value;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    return '$day/$month/$year';
  }

  List<Map<String, dynamic>> _extractStaffList(dynamic response) {
    if (response == null) return [];

    dynamic payload = response;
    for (var depth = 0; depth < 6; depth++) {
      final asList = _asMapList(payload);
      if (asList.isNotEmpty) return asList;

      if (payload is Map<String, dynamic>) {
        payload =
            payload['data'] ??
            payload['staff'] ??
            payload['staffList'] ??
            payload['staffMembers'];
        continue;
      }
      break;
    }
    return [];
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (value is Map<String, dynamic>) {
      final nested =
          value['staff'] ??
          value['staffList'] ??
          value['data'] ??
          value['items'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return [];
  }

  String _staffId(Map<String, dynamic> raw) {
    final user = raw['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    for (final value in [
      raw['id'],
      raw['staffId'],
      raw['userId'],
      userMap?['id'],
    ]) {
      final s = value?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return '';
  }

  String _staffName(Map<String, dynamic> raw) {
    final user = raw['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    for (final value in [
      raw['userName'],
      raw['name'],
      raw['fullName'],
      userMap?['userName'],
      userMap?['name'],
    ]) {
      final s = value?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return '';
  }

  bool _isActiveStaff(Map<String, dynamic> raw) {
    final user = raw['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    return _asBool(
      raw['activated'] ??
          raw['isActive'] ??
          raw['active'] ??
          raw['status'] ??
          raw['is_active'] ??
          userMap?['isActive'] ??
          userMap?['active'],
      defaultValue: false,
    );
  }

  bool _asBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return defaultValue;
    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == 'active' ||
        normalized == 'enabled') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'inactive' ||
        normalized == 'disabled' ||
        normalized == 'pending') {
      return false;
    }
    return defaultValue;
  }
}
