// Controller
import 'dart:async';
import 'dart:io';

import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

class AddStaffController extends BaseController {
  StaffMember? editingStaff;

  final formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final addressController = TextEditingController();
  final stateController = TextEditingController();
  final districtController = TextEditingController();
  final pincodeController = TextEditingController();
  final selectedRole = 'Secondary Admin'.obs;
  final selectedGender = ''.obs;
  final selectedDateOfBirth = Rxn<DateTime>();
  final selectedPermissions = <String>{}.obs;
  final selectedImage = Rx<File?>(null);
  final imageUrl = ''.obs;
  final isUploadingImage = false.obs;
  final showValidationErrors = false.obs;

  Timer? _emailCheckDebounce;
  final isEmailChecking = false.obs;
  final isEmailAvailable = Rxn<bool>();
  final emailVerificationError = RxnString();
  String? _lastCheckedEmail;

  final ImagePicker _imagePicker = ImagePicker();

  static const List<String> roleOptions = ['Secondary Admin', 'Biller'];
  static const List<String> genderOptions = ['Male', 'Female', 'Other'];
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,}$');
  static final _random = Random();

  bool get isEditMode => editingStaff != null;

  bool get hasStaffImage =>
      selectedImage.value != null || imageUrl.value.trim().isNotEmpty;

  String get dateOfBirthLabel {
    final date = selectedDateOfBirth.value;
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void onClose() {
    _emailCheckDebounce?.cancel();
    userNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    stateController.dispose();
    districtController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  String _uniqueId = '';

  static String generateUniqueId() =>
      (100000 + _random.nextInt(900000)).toString();

  void assignUniqueId([String? existing]) {
    final value = existing?.trim() ?? '';
    _uniqueId = value.isNotEmpty ? value : generateUniqueId();
  }

  void prepareScreen(StaffMember? member) {
    clearForm();
    if (member == null) return;

    editingStaff = member;
    userNameController.text = member.name;
    assignUniqueId(member.uniqueId);
    emailController.text = member.email;
    phoneNumberController.text = _normalizePhone(member.phone);
    addressController.text = member.address;
    stateController.text = member.state;
    districtController.text = member.district;
    pincodeController.text = member.pincode;
    selectedGender.value = _normalizeGender(member.gender);
    selectedDateOfBirth.value = _parseDateOfBirth(member.dateOfBirth);
    selectedRole.value = _normalizeRole(member.role);
    imageUrl.value = member.profileImage;
    selectedPermissions
      ..clear()
      ..addAll(expandStaffPermissions(member.permissions));
    isEmailAvailable.value = true;
    _lastCheckedEmail = member.email.trim().toLowerCase();
  }

  void onRoleChanged(String? role) {
    final next = role ?? 'Secondary Admin';
    selectedRole.value = next;
    if (isEditMode) return;
    selectedPermissions
      ..clear()
      ..addAll(
        next == 'Secondary Admin'
            ? StaffPermissionKeys.secondaryAdminDefaults
            : StaffPermissionKeys.billerDefaults,
      );
  }

  void togglePermission(String key, bool enabled) {
    if (enabled) {
      selectedPermissions.add(key);
    } else {
      selectedPermissions.remove(key);
    }
  }

  void selectAllPermissions() {
    selectedPermissions
      ..clear()
      ..addAll(StaffPermissionKeys.all);
  }

  void deselectAllPermissions() {
    selectedPermissions.clear();
  }

  String? validateUserName(String? value) {
    final loc = AppLocalizations.of(Get.context!)!;
    if (value == null || value.trim().isEmpty) {
      return loc.please_enter_user_name;
    }
    return null;
  }

  String? validateEmail(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    final formatError = _emailFormatError(trimmed);
    if (formatError != null) {
      return formatError;
    }
    if (isEmailAvailable.value == false) {
      return 'This email is already registered. Please use a different email.';
    }
    return null;
  }

  String? validatePhone(String? value) {
    final loc = AppLocalizations.of(Get.context!)!;
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return loc.please_enter_phone_number;
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return loc.please_enter_valid_10_digit_phone;
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (isEditMode) return null;
    final loc = AppLocalizations.of(Get.context!)!;
    if (value == null || value.trim().isEmpty) {
      return loc.please_enter_address;
    }
    return null;
  }

  String? validateState(String? value) {
    if (isEditMode) return null;
    final loc = AppLocalizations.of(Get.context!)!;
    if (value == null || value.trim().isEmpty) {
      return loc.please_enter_state;
    }
    return null;
  }

  String? validateDistrict(String? value) {
    if (isEditMode) return null;
    final loc = AppLocalizations.of(Get.context!)!;
    if (value == null || value.trim().isEmpty) {
      return loc.please_enter_district;
    }
    return null;
  }

  String? validatePincode(String? value) {
    final loc = AppLocalizations.of(Get.context!)!;
    final pincode = value?.trim() ?? '';
    if (pincode.isEmpty) {
      return isEditMode ? null : loc.please_enter_pincode;
    }
    if (pincode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pincode)) {
      return loc.please_enter_valid_pincode;
    }
    return null;
  }

  String? validateGender(String? value) {
    if (isEditMode) return null;
    final loc = AppLocalizations.of(Get.context!)!;
    if (value == null || value.trim().isEmpty) return loc.select_gender;
    return null;
  }

  String? validateDateOfBirth() {
    if (isEditMode) return null;
    final loc = AppLocalizations.of(Get.context!)!;
    if (selectedDateOfBirth.value == null) {
      return loc.please_select_date_of_birth;
    }
    return null;
  }

  bool _validateForm() {
    showValidationErrors.value = true;
    final formValid = formKey.currentState?.validate() ?? false;
    if (isEditMode) {
      return formValid;
    }
    final genderValid = validateGender(
          selectedGender.value.isEmpty ? null : selectedGender.value,
        ) ==
        null;
    final dobValid = validateDateOfBirth() == null;
    return formValid && genderValid && dobValid;
  }

  Future<void> pickStaffImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      selectedImage.value = File(image.path);
    } catch (e) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.please_select_image_first);
    }
  }

  void removeStaffImage() {
    selectedImage.value = null;
    imageUrl.value = '';
  }

  Future<void> pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = selectedDateOfBirth.value ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) {
      selectedDateOfBirth.value = picked;
    }
  }

  Future<bool> _ensureStaffImageUploaded() async {
    if (selectedImage.value == null) {
      return imageUrl.value.trim().isNotEmpty;
    }

    final outletId = appPref.selectedOutlet?.id;
    final ownerId = appPref.ownerUserId;
    if (outletId == null ||
        outletId.isEmpty ||
        ownerId == null ||
        ownerId.isEmpty) {
      return false;
    }

    isUploadingImage.value = true;
    try {
      final response = await callApi(
        MediaApi().uploadImage(
          file: selectedImage.value!,
          folderName: 'staff',
          outletId: outletId,
          userId: ownerId,
        ),
        showLoader: false,
      );
      final url = response?.data?['url']?.toString().trim() ?? '';
      if (url.isEmpty) return false;
      imageUrl.value = url;
      return true;
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> sendInvite([BuildContext? screenContext]) async {
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

    if (!_validateForm()) return;
    if (!await _ensureEmailAvailable()) return;
    if (selectedImage.value != null && !await _ensureStaffImageUploaded()) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.please_select_staff_image);
      return;
    }

    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      showError(description: loc.no_outlet_selected);
      return;
    }

    final role = selectedRole.value == 'Secondary Admin'
        ? 'secondary_admin'
        : 'biller';

    final response = await callApi(
      apiClient.addStaff(outletId, _buildStaffPayload(role: role)),
    );

    if (response == null) return;

    final message = loc.invite_sent_successfully;
    clearForm();
    await _finishWithSuccess(
      result: {'created': true, 'message': message},
      message: message,
      screenContext: screenContext,
    );
  }

  void clearForm() {
    editingStaff = null;
    showValidationErrors.value = false;
    userNameController.clear();
    emailController.clear();
    phoneNumberController.clear();
    addressController.clear();
    stateController.clear();
    districtController.clear();
    pincodeController.clear();
    selectedRole.value = 'Secondary Admin';
    selectedGender.value = '';
    selectedDateOfBirth.value = null;
    selectedImage.value = null;
    imageUrl.value = '';
    selectedPermissions
      ..clear()
      ..addAll(StaffPermissionKeys.secondaryAdminDefaults);
    assignUniqueId();
    _resetEmailVerification();
    formKey.currentState?.reset();
  }

  void _resetEmailVerification() {
    _emailCheckDebounce?.cancel();
    isEmailChecking.value = false;
    isEmailAvailable.value = null;
    emailVerificationError.value = null;
    _lastCheckedEmail = null;
  }

  void onEmailChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    emailVerificationError.value = null;

    if (_emailFormatError(trimmed) != null) {
      isEmailAvailable.value = null;
      _lastCheckedEmail = null;
      isEmailChecking.value = false;
      return;
    }

    if (isEditMode &&
        trimmed == editingStaff!.email.trim().toLowerCase()) {
      isEmailAvailable.value = true;
      _lastCheckedEmail = trimmed;
      isEmailChecking.value = false;
      return;
    }

    if (trimmed == _lastCheckedEmail) return;

    _emailCheckDebounce?.cancel();
    isEmailAvailable.value = null;
    isEmailChecking.value = true;

    _emailCheckDebounce = Timer(const Duration(milliseconds: 600), () {
      checkEmailAvailability(trimmed);
    });
  }

  String? _emailFormatError(String email) {
    final loc = AppLocalizations.of(Get.context!)!;
    if (email.isEmpty) return loc.please_enter_email;
    if (!_emailRegex.hasMatch(email)) return loc.please_enter_valid_email;
    return null;
  }

  Future<bool> checkEmailAvailability(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_emailFormatError(normalizedEmail) != null) {
      isEmailAvailable.value = null;
      emailVerificationError.value = null;
      isEmailChecking.value = false;
      return false;
    }

    if (isEditMode &&
        normalizedEmail == editingStaff!.email.trim().toLowerCase()) {
      isEmailAvailable.value = true;
      _lastCheckedEmail = normalizedEmail;
      emailVerificationError.value = null;
      isEmailChecking.value = false;
      return true;
    }

    final outletId = appPref.selectedOutlet?.id?.trim() ?? '';
    if (outletId.isEmpty) {
      isEmailAvailable.value = null;
      _lastCheckedEmail = null;
      emailVerificationError.value =
          'Could not verify email right now. Please try again.';
      isEmailChecking.value = false;
      return false;
    }

    isEmailChecking.value = true;
    emailVerificationError.value = null;

    try {
      final body = <String, dynamic>{'email': normalizedEmail};
      final staffId = editingStaff?.id.trim();
      if (staffId != null && staffId.isNotEmpty) {
        body['staffId'] = staffId;
      }

      final response = await callApi(
        apiClient.checkStaffEmail(outletId, body),
        showLoader: false,
        apiErrorHandler: (_) async => true,
      );

      if (emailController.text.trim().toLowerCase() != normalizedEmail) {
        return false;
      }

      if (response == null || response is! Map) {
        isEmailAvailable.value = null;
        _lastCheckedEmail = null;
        emailVerificationError.value =
            'Could not verify email right now. Please try again.';
        return false;
      }

      final data = Map<String, dynamic>.from(response);
      _lastCheckedEmail = normalizedEmail;

      if (data['available'] == true) {
        isEmailAvailable.value = true;
        emailVerificationError.value = null;
        return true;
      }

      if (data['available'] == false) {
        isEmailAvailable.value = false;
        emailVerificationError.value = null;
        return false;
      }

      isEmailAvailable.value = null;
      emailVerificationError.value =
          'Could not verify email right now. Please try again.';
      return false;
    } catch (_) {
      if (emailController.text.trim().toLowerCase() == normalizedEmail) {
        isEmailAvailable.value = null;
        _lastCheckedEmail = null;
        emailVerificationError.value =
            'Could not verify email right now. Please try again.';
      }
      return false;
    } finally {
      if (emailController.text.trim().toLowerCase() == normalizedEmail) {
        isEmailChecking.value = false;
      }
    }
  }

  Future<bool> _ensureEmailAvailable() async {
    final email = emailController.text.trim().toLowerCase();
    if (isEmailChecking.value) {
      showError(description: 'Please wait while we verify your email.');
      return false;
    }

    if (isEditMode && email == editingStaff!.email.trim().toLowerCase()) {
      return true;
    }

    if (_lastCheckedEmail != email || isEmailAvailable.value != true) {
      await checkEmailAvailability(email);
    }

    if (isEmailAvailable.value == false) {
      showError(
        description:
            'This email is already registered. Please use a different email.',
      );
      return false;
    }

    return true;
  }

  Future<void> onUpdateStaff([BuildContext? screenContext]) async {
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

    if (!_validateForm()) return;
    if (!await _ensureEmailAvailable()) return;
    if (selectedImage.value != null && !await _ensureStaffImageUploaded()) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.please_select_staff_image);
      return;
    }

    final staffId = editingStaff?.id.trim() ?? '';
    final loc = AppLocalizations.of(Get.context!)!;
    if (staffId.isEmpty) {
      showError(description: loc.unable_to_update_staff);
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null || outletId.isEmpty) {
      showError(description: loc.no_outlet_selected);
      return;
    }

    final role = selectedRole.value == 'Secondary Admin'
        ? 'secondary_admin'
        : 'biller';

    final response = await callApi(
      apiClient.updateStaff(
        outletId,
        staffId,
        _buildStaffPayload(role: role),
      ),
    );
    if (response == null) return;

    final message = loc.staff_member_updated_successfully;
    await _finishWithSuccess(
      result: {'updated': true, 'message': message},
      message: message,
      screenContext: screenContext,
    );
  }

  Map<String, dynamic> _buildStaffPayload({required String role}) {
    if (_uniqueId.isEmpty) {
      assignUniqueId();
    }
    final payload = <String, dynamic>{
      'userName': userNameController.text.trim(),
      'email': emailController.text.trim(),
      'userPhoneNumber': '+91${phoneNumberController.text.trim()}',
      'userRole': role,
      'permissions': _buildPermissions(role),
      'uniqueId': _uniqueId,
      'address': addressController.text.trim(),
      'state': stateController.text.trim(),
      'district': districtController.text.trim(),
      'pincode': pincodeController.text.trim(),
      'gender': selectedGender.value.trim().toLowerCase(),
    };

    final profileImage = imageUrl.value.trim();
    if (profileImage.isNotEmpty || isEditMode) {
      payload['profileImage'] = profileImage;
    }

    final dateOfBirth = selectedDateOfBirth.value;
    if (dateOfBirth != null) {
      payload['dateOfBirth'] = DateFormat('yyyy-MM-dd').format(dateOfBirth);
    }

    return payload;
  }

  Future<void> _finishWithSuccess({
    required Map<String, dynamic> result,
    required String message,
    BuildContext? screenContext,
  }) async {
    if (Get.isRegistered<StaffDetailsController>()) {
      await Get.find<StaffDetailsController>().loadStaffList();
    }

    final context = screenContext ?? Get.context;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    } else if (Modular.to.canPop()) {
      Modular.to.pop(result);
    } else {
      Get.back(result: result);
    }

    showSuccess(description: message);
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase().replaceAll('_', ' ');
    if (normalized == 'secondary admin') return 'Secondary Admin';
    if (normalized == 'biller') return 'Biller';
    return role.isEmpty ? 'Secondary Admin' : role;
  }

  String _normalizeGender(String gender) {
    final normalized = gender.trim().toLowerCase();
    if (normalized == 'male') return 'Male';
    if (normalized == 'female') return 'Female';
    if (normalized == 'other') return 'Other';
    return gender;
  }

  DateTime? _parseDateOfBirth(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      return DateTime.parse(text);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(text);
      } catch (_) {
        return null;
      }
    }
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  List<String> _buildPermissions(String role) {
    final selected = selectedPermissions
        .where((key) => StaffPermissionKeys.all.contains(key))
        .toList()
      ..sort();
    if (selected.isNotEmpty) return selected;
    return role == 'secondary_admin'
        ? List<String>.from(StaffPermissionKeys.secondaryAdminDefaults)
        : List<String>.from(StaffPermissionKeys.billerDefaults);
  }
}
