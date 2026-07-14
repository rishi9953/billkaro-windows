import 'dart:io';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/services/Modals/businessType/businesst_type_response.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/gstin_verify_helper.dart';
import 'package:billkaro/utils/staff_outlet_sync.dart';

class BusinessDetailsController extends BaseController {
  // ---------------- TEXT CONTROLLERS ----------------
  final businessNameController = TextEditingController();
  final phoneController = TextEditingController();
  final outletAddressController = TextEditingController();
  final upiIdController = TextEditingController();
  final footerMessageController = TextEditingController(
    text: 'Thank you for doing business with us.',
  );
  final fssaiController = TextEditingController();
  final gstinController = TextEditingController();
  final businessAddressController = TextEditingController();
  final googleProfileController = TextEditingController();
  final swiggyLinkController = TextEditingController();
  final zomatoLinkController = TextEditingController();

  // ---------------- RX VALUES ----------------
  final selectedTaxSlab = 'None'.obs;
  final selectedSeatingCapacity = '0'.obs;
  final selectedBusinessType = 'none'.obs;
  final selectedBusinessCategory = 'None'.obs;
  final imageUrl = ''.obs;
  final gstinVerify = GstinVerifyHelper();

  final Rx<File?> businessLogo = Rx<File?>(null);
  final Rx<OutletData?> selectedOutlet = Rx<OutletData?>(null);
  final RxList<BusinessType> businessTypesList = <BusinessType>[].obs;

  static const _fallbackBusinessTypeOptions = [
    'none',
    'retail',
    'service',
    'manufacturing',
    'other',
  ];

  /// Values used by the business type dropdown (API when loaded, else fallback).
  List<String> get businessTypeOptions {
    if (businessTypesList.isEmpty) {
      return _fallbackBusinessTypeOptions;
    }
    final active = businessTypesList.where((e) => e.active).toList();
    final values = <String>['none'];
    for (final e in active) {
      final v = e.value.trim().toLowerCase();
      if (v.isEmpty || values.contains(v)) continue;
      values.add(v);
    }
    return values;
  }

  void _ensureBusinessTypeSelection() {
    final outletType =
        selectedOutlet.value?.businessType?.trim().toLowerCase();
    final opts = businessTypeOptions;
    var cur = selectedBusinessType.value.trim().toLowerCase();

    if (cur.isEmpty || cur == 'none') {
      if (outletType != null && outletType.isNotEmpty) {
        selectedBusinessType.value = outletType;
        cur = outletType;
      }
    }

    if (opts.contains(cur)) {
      if (selectedBusinessType.value != cur) {
        selectedBusinessType.value = cur;
      }
      return;
    }

    if (outletType != null && outletType.isNotEmpty) {
      selectedBusinessType.value = outletType;
      return;
    }

    selectedBusinessType.value = opts.first;
  }

  /// Seating capacity applies only to cafe and restaurant outlets.
  bool get showSeatingCapacityField {
    final t = selectedBusinessType.value.toLowerCase();
    return t == 'cafe' || t == 'restaurant';
  }

  // ---------------- OPTIONS ----------------
  final taxSlabOptions = const ['None', '5%', '12%', '18%', '28%'];
  final seatingCapacityOptions = const [
    {'label': 'No Seating', 'value': '0'},
    {'label': 'Less than 10', 'value': '0-10'},
    {'label': '10-20', 'value': '10-20'},
    {'label': '20-50', 'value': '20-50'},
    {'label': '50-100', 'value': '50-100'},
    {'label': 'More than 100', 'value': '100+'},
  ];

  static const _seatingValueKeys = [
    '0',
    '0-10',
    '10-20',
    '20-50',
    '50-100',
    '100+',
  ];
  static String _seatingCapacityToValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '0';
    final t = raw.trim();
    if (_seatingValueKeys.contains(t)) return t;
    final lower = t.toLowerCase();
    if (lower.contains('no seating')) return '0';
    if (lower.contains('less') && lower.contains('10')) return '0-10';
    if (lower.contains('more') && lower.contains('100')) return '100+';
    if (lower == '10-20') return '10-20';
    if (lower == '20-50') return '20-50';
    if (lower == '50-100') return '50-100';
    return '0';
  }

  final businessCategoryOptions = const [
    'None',
    'Fine Dining',
    'Casual Dining',
    'Fast Food',
    'Bakery',
    'Desserts',
  ];

  // ---------------- LIFECYCLE ----------------
  @override
  void onInit() {
    super.onInit();
    syncOutletFromAppPref();
    gstinController.addListener(_handleGstinChanged);
  }

  void _handleGstinChanged() {
    gstinVerify.resetIfChanged(gstinController.text);
  }

  @override
  void onReady() {
    super.onReady();
    getBusinessTypes();
    getUserDetails();
  }

  Future<void> getBusinessTypes() async {
    final response = await callApi(
      apiClient.getBusinessTypes(true),
      showLoader: false,
    );
    if (response != null && response.status == 'success') {
      businessTypesList.assignAll(response.data);
      _ensureBusinessTypeSelection();
      syncOutletFromAppPref();
    }
  }

  void refreshData() {
    getBusinessTypes();
    getUserDetails();
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image != null) {
      businessLogo.value = File(image.path);
    }
  }

  /// Sync form fields from [appPref.selectedOutlet] after user switches outlet elsewhere (no API).
  void syncOutletFromAppPref() {
    final outlet = appPref.selectedOutlet;
    selectedOutlet.value = outlet;
    if (outlet == null) return;

    businessNameController.text = outlet.businessName ?? '';
    phoneController.text = appPref.user?.mobile ?? '';

    selectedBusinessType.value = outlet.businessType?.toLowerCase() ?? 'none';
    selectedTaxSlab.value = outlet.taxSlab?.isNotEmpty == true
        ? outlet.taxSlab!
        : 'None';
    selectedSeatingCapacity.value = _seatingCapacityToValue(
      outlet.seatingCapacity,
    );
    selectedBusinessCategory.value = outlet.businessCategory?.isNotEmpty == true
        ? outlet.businessCategory!
        : 'None';
    imageUrl.value = outlet.logo ?? '';
    outletAddressController.text = outlet.outletAddress ?? '';
    upiIdController.text = outlet.upiId ?? '';
    fssaiController.text = outlet.fssaiNumber ?? '';
    gstinController.text = outlet.gstinNumber ?? '';
    gstinVerify.markSavedFromServer(outlet.gstinNumber);
    googleProfileController.text = outlet.googleProfileLink ?? '';
    swiggyLinkController.text = outlet.swiggyLink ?? '';
    zomatoLinkController.text = outlet.zomatoLink ?? '';
    businessAddressController.text = appPref.user!.address ?? '';
    _ensureBusinessTypeSelection();
  }

  // ---------------- FETCH USER & OUTLET ----------------
  Future<void> getUserDetails() async {
    try {
      final currentUser = appPref.user;
      if (currentUser == null) return;

      final bool isStaff = currentUser.role == 'staff';
      final res = await callApi(
        isStaff
            ? apiClient.getStaffProfile(currentUser.id!)
            : apiClient.getUserDetails(appPref.ownerUserId ?? ''),
        showLoader: false,
      );

      if (res?.status != 'success') return;

      if (isStaff) {
        await StaffOutletSync.enrichAppPrefFromOwner(
          appPref: appPref,
          staffUser: res!.data,
          apiClient: apiClient,
        );
      } else {
        appPref.user = res!.data;
      }

      // ✅ Get fresh outlets list from server response
      final serverOutlets = appPref.user?.outletData ?? [];
      debugPrint('✅ Refreshed ${serverOutlets.length} outlets from server');

      // ✅ Find the current outlet by ID in the fresh data
      final currentOutletId = appPref.selectedOutlet?.id;
      if (currentOutletId != null && serverOutlets.isNotEmpty) {
        final freshOutlet = serverOutlets.firstWhere(
          (outlet) => outlet.id == currentOutletId,
          orElse: () => serverOutlets.first,
        );
        appPref.selectedOutlet = freshOutlet;
        selectedOutlet.value = freshOutlet;
      } else if (serverOutlets.isNotEmpty) {
        appPref.selectedOutlet = serverOutlets.first;
        selectedOutlet.value = serverOutlets.first;
      }

      syncOutletFromAppPref();
    } catch (e) {
      debugPrint('❌ getUserDetails error: $e');
      showError(description: 'Failed to load business details');
    }
  }

  // ---------------- UPDATE BUSINESS ----------------
  Future<void> updateBusinessDetails() async {
    try {
      debugPrint('🔄 Updating business details...');
      if (gstinVerify.requiresVerification(gstinController.text)) {
        showError(description: 'Please verify GSTIN before updating details');
        return;
      }

      showAppLoader();
      // ✅ Upload image if selected
      if (businessLogo.value != null) {
        await uploadItemImage();
      }

      // ✅ Update user details
      final userPayload = User(
        id: appPref.user?.id,
        address: businessAddressController.text,
        mobile: phoneController.text,
        title: appPref.user?.title,
      ).toJson()..removeWhere((k, v) => v == null || v.toString().isEmpty);

      final ownerId = appPref.ownerUserId;
      if (ownerId == null) {
        showError(description: 'Failed to load business details');
        return;
      }

      final userRes = await callApi(
        apiClient.updateUser(ownerId, userPayload),
        showLoader: false,
      );

      if (userRes['status'] != 'success') {
        showError(description: userRes['message']);
        return;
      }

      // ✅ Update outlet details
      final outletSuccess = await updateOutletDetails();
      if (!outletSuccess) return;

      // ✅ CRITICAL: Refresh ALL data from server to avoid stale data
      await getUserDetails();
      businessLogo.value = null;

      // ✅ Sync with HomeScreenController
      if (Get.isRegistered<HomeScreenController>()) {
        final homeController = Get.find<HomeScreenController>();
        homeController.selectedOutlet.value = appPref.selectedOutlet;
        homeController.update();
        debugPrint('✅ HomeScreenController outlet synced');
      }
      dismissAllAppLoader();
      showSuccess(description: 'Business details updated successfully');
    } catch (e) {
      debugPrint('❌ updateBusinessDetails error: $e');
      showError(description: 'Update failed');
    }
  }

  // ---------------- UPDATE OUTLET ----------------
  Future<bool> updateOutletDetails() async {
    final outlet = selectedOutlet.value;
    if (outlet == null) return false;

    final updatedOutlet = OutletData(
      id: outlet.id,
      businessName: businessNameController.text,
      businessType: selectedBusinessType.value,
      businessCategory: selectedBusinessCategory.value,
      taxSlab: selectedTaxSlab.value,
      seatingCapacity: selectedSeatingCapacity.value,
      outletAddress: outletAddressController.text,
      upiId: upiIdController.text,
      gstinNumber: gstinController.text,
      fssaiNumber: fssaiController.text,
      logo: imageUrl.value,
      googleProfileLink: googleProfileController.text,
      swiggyLink: swiggyLinkController.text,
      zomatoLink: zomatoLinkController.text,
    );

    final outletPayload = updatedOutlet.toJson()
      ..removeWhere((k, v) => v == null || v.toString().isEmpty);

    final ownerId = appPref.ownerUserId;
    if (ownerId == null) return false;

    final res = await callApi(
      apiClient.updateOutlet(ownerId, outlet.id!, outletPayload),
      showLoader: false,
    );

    if (res['status'] != 'success') {
      showError(description: res['message']);
      return false;
    }

    debugPrint('✅ Outlet updated on server');
    gstinVerify.markSavedAfterSubmit(gstinController.text);
    return true;
  }

  Future<void> verifyGstin() async {
    final details = await gstinVerify.verify(
      gstinController.text,
      onError: ({title, required description}) => showError(
        title: title,
        description: description,
      ),
      onSuccess: ({title, required description}) => showSuccess(
        title: title,
        description: description,
      ),
    );

    if (details == null || !gstinVerify.isGstinVerified.value) return;

    if (businessNameController.text.trim().isEmpty &&
        details.legalName != null) {
      businessNameController.text = details.legalName!;
    }
    if (outletAddressController.text.trim().isEmpty &&
        details.principalAddress != null) {
      outletAddressController.text = details.principalAddress!;
    }
  }

  // ---------------- DELETE OUTLET ----------------
  Future<void> deleteOutlet() async {
    final outlet = selectedOutlet.value;
    if (outlet == null) return;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Outlet'),
        content: Text(
          'Delete ${outlet.businessName} ?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ownerId = appPref.ownerUserId;
      if (ownerId == null) return;

      final res = await callApi(
        apiClient.deleteOutlet(ownerId, outlet.id!),
      );

      if (res['status'] != 'success') {
        showError(description: res['message']);
        return;
      }

      // ✅ Refresh from server to get clean state
      await getUserDetails();

      Get.offAllNamed(AppRoute.homeMain);
    } catch (e) {
      debugPrint('❌ deleteOutlet error: $e');
      showError(description: 'Failed to delete outlet');
    }
  }

  // ---------------- IMAGE UPLOAD ----------------
  Future<void> uploadItemImage() async {
    final outletId = appPref.selectedOutlet?.id;
    final ownerId = appPref.ownerUserId;
    if (outletId == null || ownerId == null) return;

    debugPrint('📤 Uploading image for outlet: $outletId');

    final res = await callApi(
      MediaApi().uploadImage(
        file: businessLogo.value!,
        folderName: 'users',
        outletId: outletId,
        userId: ownerId,
      ),
      showLoader: false,
    );

    if (res?.data?['url'] != null) {
      imageUrl.value = res!.data['url'];
      debugPrint('✅ Image uploaded: ${imageUrl.value}');
    }
  }

  // ---------------- DISPOSE ----------------
  @override
  void onClose() {
    gstinController.removeListener(_handleGstinChanged);
    for (final c in [
      businessNameController,
      phoneController,
      outletAddressController,
      upiIdController,
      footerMessageController,
      fssaiController,
      gstinController,
      businessAddressController,
      googleProfileController,
      swiggyLinkController,
      zomatoLinkController,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
