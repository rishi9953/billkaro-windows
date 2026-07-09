import 'dart:async';

import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_controller.dart';
import 'package:billkaro/app/services/Modals/businessType/businesst_type_response.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/outlets/outlet_request.dart';
import 'package:billkaro/app/services/outlet_scope_refresh.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_outlet_sync.dart';

class CreateOutletController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final Rx<OutletData?> selectedOutlet = Rx<OutletData?>(null);
  final RxList<BusinessType> businessTypesList = <BusinessType>[].obs;
  final isCreating = false.obs;

  final outletName = ''.obs;
  final selectedType = 'None'.obs;
  final selectedCapacity = '0-10'.obs;
  final selectedAge = 'Less than 6 Months'.obs;
  final outletAddress = ''.obs;

  static const List<String> _fallbackTypeOptions = [
    'Retail',
    'Service',
    'Manufacturing',
    'Other',
    'None',
  ];

  List<String> get typeOptions {
    if (businessTypesList.isEmpty) return _fallbackTypeOptions;
    final active = businessTypesList.where((e) => e.active).toList();
    final out = <String>[];
    for (final e in active) {
      final name = e.name.trim();
      if (name.isEmpty || out.contains(name)) continue;
      out.add(name);
    }
    if (!out.contains('None')) out.add('None');
    return out.isEmpty ? _fallbackTypeOptions : out;
  }

  bool get showSeatingCapacityField {
    final typeValue = _businessTypeValueForSelected();
    return typeValue == 'cafe' || typeValue == 'restaurant';
  }

  final capacityOptions = const [
    {'label': 'No Seating', 'value': '0'},
    {'label': 'Less than 10', 'value': '0-10'},
    {'label': '10-20', 'value': '10-20'},
    {'label': '20-50', 'value': '20-50'},
    {'label': '50-100', 'value': '50-100'},
    {'label': 'More than 100', 'value': '100+'},
  ];

  final ageOptions = const [
    'Less than 6 Months',
    '6 Months - 1 Year',
    '1-2 Years',
    '2-5 Years',
    'More than 5 Years',
  ];

  @override
  void onInit() {
    super.onInit();
    getBusinessTypes();
  }

  String _businessTypeValueForSelected() {
    final selected = selectedType.value.trim();
    if (selected.isEmpty) return 'none';

    for (final e in businessTypesList) {
      if (e.name.trim().toLowerCase() == selected.toLowerCase()) {
        return e.value.trim().toLowerCase();
      }
    }
    return selected.toLowerCase();
  }

  void _ensureBusinessTypeSelection() {
    final options = typeOptions;
    if (options.isEmpty) return;
    final current = selectedType.value.trim().toLowerCase();
    final match = options.firstWhereOrNull(
      (o) => o.trim().toLowerCase() == current,
    );
    selectedType.value = match ?? options.first;
  }

  Future<void> getBusinessTypes() async {
    final response = await callApi(
      apiClient.getBusinessTypes(true),
      showLoader: false,
    );
    if (response != null && response.status == 'success') {
      businessTypesList.assignAll(response.data);
      _ensureBusinessTypeSelection();
    }
  }

  String? validateBusinessType(String? value) {
    final selected = (value ?? selectedType.value).trim();
    if (selected.isEmpty || selected.toLowerCase() == 'none') {
      return 'Please select a business type';
    }
    return null;
  }

  Future<void> createOutlet() async {
    if (isCreating.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final typeValue = _businessTypeValueForSelected();
    if (typeValue == 'none') {
      showError(description: 'Please select a business type');
      // Get.snackbar(
      //   'Missing type',
      //   'Please select a business type',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      return;
    }

    isCreating.value = true;
    try {
      final request = OutletRequest(
        businessName: outletName.value.trim(),
        businessType: typeValue,
        seatingCapacity: showSeatingCapacityField
            ? selectedCapacity.value
            : '0',
        outletAge: selectedAge.value,
        outletAddress: outletAddress.value.trim(),
      );
      final response = await callApi(
        apiClient.addOutlet(appPref.user!.id!, request),
        showLoader: false,
      );
      if (response is Map && response['status'] == 'success') {
        await getUserDetails();
        _finishAfterOutletCreated();
      }
    } finally {
      isCreating.value = false;
    }
  }

  void _finishAfterOutletCreated() {
    final outlet = appPref.selectedOutlet;

    if (Get.isRegistered<HomeMainController>()) {
      final main = Get.find<HomeMainController>();
      main.selectedOutlet.value = outlet;
      main.update();
    }

    if (Get.isRegistered<HomeScreenController>()) {
      final home = Get.find<HomeScreenController>();
      home.selectedOutlet.value = outlet;
      home.onOutletChanged();
    } else {
      unawaited(refreshOutletScopedControllers());
    }

    // Pop create-outlet route only — do not restart HomeMainScreen/ModularApp.
    Get.back();

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    final name = outlet?.businessName?.trim();

    showSuccess(
      description: name != null && name.isNotEmpty
          ? '$name is now active'
          : 'Your new outlet is ready',
    );
  }

  Future<void> getUserDetails() async {
    if (appPref.isStaffSession) {
      final staffId = appPref.user?.id;
      if (staffId == null || staffId.isEmpty) return;

      final response = await callApi(apiClient.getStaffProfile(staffId));
      if (response?.status == 'success') {
        await StaffOutletSync.enrichAppPrefFromOwner(
          appPref: appPref,
          staffUser: response!.data,
          apiClient: apiClient,
        );
        selectedOutlet.value = appPref.selectedOutlet;
      }
      return;
    }

    final ownerId = appPref.ownerUserId;
    if (ownerId == null || ownerId.isEmpty) return;

    final response = await callApi(apiClient.getUserDetails(ownerId));
    if (response?.status == 'success') {
      appPref.user = response!.data;

      if (appPref.allOutlets.isNotEmpty) {
        final lastOutlet = appPref.allOutlets.last;
        appPref.selectedOutlet = lastOutlet;
        selectedOutlet.value = lastOutlet;
        debugPrint(
          '🏪 Auto-selected recently created outlet: ${lastOutlet.businessName}',
        );
      } else if (!appPref.hasSelectedOutlet && appPref.allOutlets.isNotEmpty) {
        appPref.selectFirstOutlet();
        selectedOutlet.value = appPref.selectedOutlet;
      }
    }
  }
}
