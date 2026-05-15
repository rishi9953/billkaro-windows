import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/services/Modals/activites/activities_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

class StaffActivityController extends BaseController {
  static const int _activityPageLimit = 20;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final activities = <ActivityModel>[].obs;

  final activitiesPage = 1.obs;
  final activitiesTotalPages = 1.obs;

  final staffList = <Map<String, dynamic>>[].obs;
  final List<String> timePeriods = const <String>[
    'Today',
    'This week',
    'This month',
    'This quarter',
    'This Financial Year',
    'Custom',
  ];

  final RxString selectedTimePeriod = 'Today'.obs;
  final Rxn<DateTime> selectedFromDate = Rxn<DateTime>(DateTime.now());
  final Rxn<DateTime> selectedToDate = Rxn<DateTime>(DateTime.now());
  final RxString selectedUserName = 'Users'.obs;
  final RxString selectedUserId = ''.obs;

  final List<String> activityTypes = const <String>[
    'All Activities',
    'Order Added',
    'Order Deleted',
    'Customer Added',
    'Customer Deleted',
    'Customer Edited',
    'Item Added',
    'Item Deleted',
    'Item Edited',
  ];

  final RxString selectedActivityType = 'All Activities'.obs;

  String get activityTypeFilterLabel =>
      selectedActivityType.value == 'All Activities'
      ? 'Activity Type'
      : selectedActivityType.value;

  List<StaffMember> get staffMembers =>
      staffList.map(_toStaffMember).toList(growable: false);

  String? _activitiesTypeQueryParam(String selected) {
    if (selected == 'All Activities') return null;
    final normalized = selected.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> applyActivityType(String value) async {
    selectedActivityType.value = value;
    await getStaffActivities();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  ({DateTime start, DateTime end}) _activityDateBounds() {
    final now = DateTime.now();
    if (selectedTimePeriod.value == 'Custom') {
      var from = _dateOnly(selectedFromDate.value ?? now);
      var to = _dateOnly(selectedToDate.value ?? now);
      if (to.isBefore(from)) {
        final tmp = from;
        from = to;
        to = tmp;
      }
      return (start: from, end: to);
    }

    switch (selectedTimePeriod.value) {
      case 'Today':
        final d = _dateOnly(now);
        return (start: d, end: d);
      case 'This week':
        final monday = _dateOnly(
          now.subtract(Duration(days: now.weekday - DateTime.monday)),
        );
        final sunday = _dateOnly(monday.add(const Duration(days: 6)));
        return (start: monday, end: sunday);
      case 'This month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return (start: start, end: end);
      case 'This quarter':
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(now.year, startMonth, 1);
        final end = DateTime(now.year, startMonth + 3, 0);
        return (start: start, end: end);
      case 'This Financial Year':
        if (now.month >= 4) {
          return (
            start: DateTime(now.year, 4, 1),
            end: DateTime(now.year + 1, 3, 31),
          );
        }
        return (
          start: DateTime(now.year - 1, 4, 1),
          end: DateTime(now.year, 3, 31),
        );
      default:
        final d = _dateOnly(now);
        return (start: d, end: d);
    }
  }

  Future<void> applyTimePeriod(String value) async {
    selectedTimePeriod.value = value;
    if (value != 'Custom') {
      final bounds = _activityDateBounds();
      selectedFromDate.value = bounds.start;
      selectedToDate.value = bounds.end;
    }
    await getStaffActivities();
  }

  void resetTimePeriod() {
    selectedTimePeriod.value = 'Today';
  }

  Future<void> applyUserSelection(StaffMember? member) async {
    if (member == null) {
      selectedUserId.value = '';
      selectedUserName.value = 'Users';
    } else {
      selectedUserId.value = member.id;
      selectedUserName.value = member.name.isNotEmpty ? member.name : 'Users';
    }
    await getStaffActivities();
  }

  String get selectedDateRangeLabel {
    final from = selectedFromDate.value;
    final to = selectedToDate.value;
    if (from == null || to == null) return 'Select Date';
    return '${_formatDate(from)} TO ${_formatDate(to)}';
  }

  void applyDateRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) return;
    selectedFromDate.value = from;
    selectedToDate.value = to;
    selectedTimePeriod.value = 'Custom';
  }

  Future<void> applyDateRangeAndRefresh(DateTime? from, DateTime? to) async {
    applyDateRange(from, to);
    await getStaffActivities();
  }

  Future<void> resetDateRange() async {
    final now = DateTime.now();
    final d = _dateOnly(now);
    selectedFromDate.value = d;
    selectedToDate.value = d;
    selectedTimePeriod.value = 'Today';
    await getStaffActivities();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  bool get hasMoreActivities =>
      activitiesPage.value < activitiesTotalPages.value;

  Future<void> loadMoreActivities() async {
    await getStaffActivities(append: true);
  }

  Future<void> getStaffActivities({bool append = false}) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      activities.clear();
      activitiesPage.value = 1;
      activitiesTotalPages.value = 1;
      return;
    }

    if (append) {
      if (isLoadingMore.value || !hasMoreActivities) return;
      isLoadingMore.value = true;
    }

    final requestPage = append ? activitiesPage.value + 1 : 1;

    try {
      final staffFilter = selectedUserId.value.trim();
      final typeFilter = _activitiesTypeQueryParam(selectedActivityType.value);
      final bounds = _activityDateBounds();
      final fmt = DateFormat('yyyy-MM-dd');
      final startDate = fmt.format(bounds.start);
      final endDate = fmt.format(bounds.end);
      final response = await callApi(
        apiClient.getActivities(
          outletId,
          staffId: staffFilter.isEmpty ? null : staffFilter,
          type: typeFilter,
          startDate: startDate,
          endDate: endDate,
          page: requestPage,
          limit: _activityPageLimit,
        ),
        showLoader: false,
      );
      if (response != null) {
        final p = response.pagination;
        final safeTotalPages = p.totalPages < 1 ? 1 : p.totalPages;

        if (!append) {
          activities.assignAll(response.data);
          activitiesPage.value = p.currentPage < 1 ? 1 : p.currentPage;
          activitiesTotalPages.value = safeTotalPages;
        } else {
          if (response.data.isEmpty) {
            activitiesTotalPages.value = activitiesPage.value;
          } else {
            activities.addAll(response.data);
            activitiesPage.value = requestPage;
            activitiesTotalPages.value = safeTotalPages;
          }
        }
      } else {
        if (!append) {
          activities.clear();
          activitiesPage.value = 1;
          activitiesTotalPages.value = 1;
        }
      }
    } finally {
      if (append) {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> refreshStaffActivityData() async {
    isLoading.value = true;
    try {
      await _loadStaffListInternal();
      await getStaffActivities();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStaffListInternal() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      staffList.clear();
      return;
    }

    final response = await callApi(
      apiClient.getStaffList(outletId),
      showLoader: false,
    );
    staffList.value = _extractStaffList(response);
  }

  @override
  void onReady() {
    super.onReady();
    refreshStaffActivityData();
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
            payload['staffMembers'] ??
            payload['users'] ??
            payload['items'] ??
            payload['result'] ??
            payload['results'] ??
            payload['payload'];
        continue;
      }
      break;
    }

    return _asMapList(response);
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
          value['staffMembers'] ??
          value['users'] ??
          value['items'] ??
          value['data'] ??
          value['result'] ??
          value['results'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return [];
  }

  StaffMember _toStaffMember(Map<String, dynamic> raw) {
    final user = raw['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final role = _asString(raw['role']).isNotEmpty
        ? _asString(raw['role'])
        : _asString(raw['userRole']).isNotEmpty
        ? _asString(raw['userRole'])
        : _asString(userMap?['role']);

    return StaffMember(
      id: _firstNonEmpty([
        raw['_id'],
        raw['id'],
        raw['staffId'],
        raw['userId'],
        userMap?['_id'],
        userMap?['id'],
        user,
      ]),
      name: _firstNonEmpty([
        raw['name'],
        raw['fullName'],
        raw['userName'],
        raw['username'],
        userMap?['name'],
        userMap?['fullName'],
        userMap?['userName'],
      ]),
      role: role.isNotEmpty ? role : 'Biller',
      phone: _firstNonEmpty([
        raw['phone'],
        raw['phoneNumber'],
        raw['userPhoneNumber'],
        raw['mobile'],
        userMap?['phone'],
        userMap?['phoneNumber'],
      ]),
      email: _firstNonEmpty([
        raw['email'],
        raw['mail'],
        userMap?['email'],
        userMap?['mail'],
      ]),
      isActive: _asBool(
        raw['activated'] ??
            raw['isActive'] ??
            raw['active'] ??
            raw['status'] ??
            raw['is_active'] ??
            userMap?['isActive'] ??
            userMap?['active'],
        defaultValue: true,
      ),
      permissions: _asStringList(raw['permissions'] ?? userMap?['permissions']),
    );
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _asString(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _asString(dynamic value) => value?.toString().trim() ?? '';

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => _asString(item))
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  bool _asBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = _asString(value).toLowerCase();
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
        normalized == 'disabled') {
      return false;
    }

    return defaultValue;
  }
}
