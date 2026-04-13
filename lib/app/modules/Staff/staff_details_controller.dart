import 'package:billkaro/config/config.dart';

class StaffDetailsController extends BaseController {
  final isLoading = false.obs;
  final staffList = <Map<String, dynamic>>[].obs;
  final deletingStaffIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadStaffList();
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

  List<Map<String, dynamic>> _extractStaffList(dynamic response) {
    if (response == null) return [];

    dynamic payload = response;
    if (payload is Map<String, dynamic>) {
      payload =
          payload['data'] ??
          payload['staff'] ??
          payload['result'] ??
          payload['results'] ??
          payload;
    }

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      final nestedList =
          payload['staff'] ??
          payload['items'] ??
          payload['users'] ??
          payload['data'];
      if (nestedList is List) {
        return nestedList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  Future<void> deleteStaffById(String staffId) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty || staffId.isEmpty) {
      showError(description: 'Unable to delete staff');
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

      showSuccess(description: 'Staff deleted successfully');
      await loadStaffList();
    } finally {
      deletingStaffIds.remove(staffId);
    }
  }
}
