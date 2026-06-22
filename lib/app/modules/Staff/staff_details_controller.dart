import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.permissions,
  });

  final String id;
  final String name;
  final String role;
  final String phone;
  final String email;
  final bool isActive;
  final List<String> permissions;
}

class StaffDetailsController extends BaseController {
  final isLoading = false.obs;
  final staffList = <Map<String, dynamic>>[].obs;
  final deletingStaffIds = <String>{}.obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  List<StaffMember> get staffMembers =>
      staffList.map(_toStaffMember).toList(growable: false);

  List<StaffMember> get filteredStaff {
    final members = staffMembers;
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return members;

    return members.where((member) {
      return member.name.toLowerCase().contains(query) ||
          member.role.toLowerCase().contains(query) ||
          member.phone.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    loadStaffList();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  Future<void> loadStaffList() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      staffList.clear();
      return;
    }

    isLoading.value = true;
    try {
      final response = await callApi(
        apiClient.getStaffList(outletId),
        showLoader: false,
      );
      staffList.value = _extractStaffList(response);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onAddStaff() async {
    final result = await Modular.to.pushNamed(HomeMainRoutes.addStaffScreen);
    final created =
        result == true || (result is Map && result['created'] == true);
    if (!created) {
      await loadStaffList();
      return;
    }
    await loadStaffList();
    final message = result is Map
        ? (result['message']?.toString() ?? '').trim()
        : '';
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(
      description: message.isNotEmpty ? message : loc.invite_sent_successfully,
    );
  }

  Future<void> onEditStaff(StaffMember member) async {
    final result = await Modular.to.pushNamed(
      HomeMainRoutes.addStaffScreen,
      arguments: member,
    );
    final isUpdated =
        result == true || (result is Map && result['updated'] == true);
    if (!isUpdated) return;
    await loadStaffList();
    final message = result is Map
        ? (result['message']?.toString() ?? '').trim()
        : '';
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(
      description: message.isNotEmpty
          ? message
          : loc.staff_member_updated_successfully,
    );
  }

  Future<void> deleteStaffById(String staffId) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty || staffId.isEmpty) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.unable_to_delete_staff);
      return;
    }
    if (deletingStaffIds.contains(staffId)) return;

    deletingStaffIds.add(staffId);
    try {
      final response = await callApi(
        apiClient.deleteStaff(outletId, staffId),
        showLoader: false,
      );
      if (response == null) return;

      final loc = AppLocalizations.of(Get.context!)!;
      showSuccess(description: loc.staff_deleted_successfully);
      await loadStaffList();
    } finally {
      deletingStaffIds.remove(staffId);
    }
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
