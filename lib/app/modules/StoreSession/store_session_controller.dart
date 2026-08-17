import 'package:billkaro/app/services/Modals/store_session/store_session_model.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_widget.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';

class StoreSessionController extends BaseController {
  final RxBool isOpen = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isActionLoading = false.obs;
  final Rx<OutletDaySession?> currentSession = Rx<OutletDaySession?>(null);
  final Rx<LiveDaySummary?> liveSummary = Rx<LiveDaySummary?>(null);

  @override
  void onReady() {
    super.onReady();
    refresh();
  }

  String? get _outletId => appPref.selectedOutlet?.id;

  @override
  Future<void> refresh({bool silent = false}) async {
    final outletId = _outletId;
    if (outletId == null || outletId.isEmpty) {
      isOpen.value = false;
      currentSession.value = null;
      liveSummary.value = null;
      return;
    }

    if (!silent) isLoading.value = true;
    try {
      final response = await callApi(
        apiClient.getCurrentDaySession(outletId),
        showLoader: false,
      );
      if (response != null && response['status'] == 'success') {
        final open = response['isOpen'] == true;
        isOpen.value = open;
        final data = response['data'];
        currentSession.value = data is Map<String, dynamic>
            ? OutletDaySession.fromJson(data)
            : null;
        if (!open) {
          liveSummary.value = null;
        }
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<LiveDaySummary?> fetchLiveSummary() async {
    final outletId = _outletId;
    if (outletId == null || outletId.isEmpty) return null;

    final response = await callApi(
      apiClient.getDaySessionSummary(outletId),
      showLoader: false,
    );
    if (response != null &&
        response['status'] == 'success' &&
        response['data'] is Map<String, dynamic>) {
      final summary = LiveDaySummary.fromJson(
        response['data'] as Map<String, dynamic>,
      );
      liveSummary.value = summary;
      return summary;
    }
    return null;
  }

  Future<bool> openStore({
    required double openingCash,
    String? notes,
  }) async {
    if (!StaffAccess.ensure(StaffAccess.canOpenStore)) return false;
    final outletId = _outletId;
    if (outletId == null || outletId.isEmpty) return false;

    isActionLoading.value = true;
    try {
      final response = await callApi(
        apiClient.openDaySession(outletId, {
          'openingCash': openingCash,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        }),
        showLoader: true,
      );
      if (response != null && response['status'] == 'success') {
        isOpen.value = true;
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          currentSession.value = OutletDaySession.fromJson(data);
        }
        return true;
      }
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> closeStore({
    double? closingCash,
    String? notes,
    bool resetTables = true,
  }) async {
    if (!StaffAccess.ensure(StaffAccess.canCloseStore)) return false;
    final outletId = _outletId;
    if (outletId == null || outletId.isEmpty) return false;

    isActionLoading.value = true;
    try {
      final body = <String, dynamic>{
        'resetTables': resetTables,
        if (closingCash != null) 'closingCash': closingCash,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      final response = await callApi(
        apiClient.closeDaySession(outletId, body),
        showLoader: true,
      );
      if (response != null && response['status'] == 'success') {
        isOpen.value = false;
        currentSession.value = null;
        liveSummary.value = null;
        return true;
      }
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  void ensureStoreOpenOrPrompt() {
    if (isOpen.value) return;
    if (!StaffAccess.canOpenStore) {
      StaffAccess.ensure(false, message: 'Store is closed. Ask a manager to open it.');
      return;
    }
    final context = Get.context;
    if (context == null) return;
    showStoreOpenDialog(context);
  }
}
