import 'dart:io';

import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/state_city_picker_helper.dart';
import 'package:intl/intl.dart';

/// Staff self-service profile (view + edit personal details / photo).
class StaffProfileController extends BaseController {
  final isLoadingProfile = true.obs;
  final isSaving = false.obs;
  final isUploadingImage = false.obs;
  final isEditMode = false.obs;

  final userNameController = TextEditingController();
  final uniqueIdController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final addressController = TextEditingController();
  final pincodeController = TextEditingController();

  final locationPicker = StateCityPickerHelper();
  final selectedGender = ''.obs;
  final selectedDateOfBirth = Rxn<DateTime>();
  final selectedImage = Rx<File?>(null);
  final imageUrl = ''.obs;

  final staffRole = ''.obs;
  final permissions = <String>[].obs;
  final outletName = ''.obs;
  final isActivated = false.obs;

  static const genderOptions = ['Male', 'Female', 'Other'];
  final ImagePicker _imagePicker = ImagePicker();

  String get displayName {
    final name = userNameController.text.trim();
    if (name.isNotEmpty) return name;
    return appPref.user?.firstName?.trim() ?? 'Staff';
  }

  String get roleLabel {
    final role = staffRole.value.trim().toLowerCase();
    if (role == 'secondary_admin' || role == 'secondary admin') {
      return 'Secondary Admin';
    }
    if (role == 'biller') return 'Biller';
    return staffRole.value.isEmpty ? 'Staff' : staffRole.value;
  }

  bool get isSecondaryAdmin {
    final role = staffRole.value.trim().toLowerCase().replaceAll(' ', '_');
    return role == 'secondary_admin';
  }

  String get dateOfBirthLabel {
    final dob = selectedDateOfBirth.value;
    if (dob == null) return '';
    return DateFormat('dd MMM yyyy').format(dob);
  }

  @override
  void onInit() {
    super.onInit();
    locationPicker.initInBackground();
    loadProfile();
  }

  @override
  void onClose() {
    userNameController.dispose();
    uniqueIdController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    final staffId = appPref.user?.id;
    if (staffId == null || staffId.isEmpty) {
      isLoadingProfile.value = false;
      showError(description: 'Staff session not found. Please sign in again.');
      return;
    }

    isLoadingProfile.value = true;
    try {
      final res = await callApi(
        apiClient.getStaffProfile(staffId),
        showLoader: false,
      );
      if (res?.status != 'success' || res?.data == null) {
        showError(description: 'Failed to load profile.');
        return;
      }
      _applyProfile(res!.data);
    } catch (e) {
      debugPrint('Staff profile load error: $e');
      showError(description: 'Failed to load profile.');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  void _applyProfile(User data) {
    final name = (data.userName ?? data.firstName ?? '').trim();
    userNameController.text = name;
    uniqueIdController.text = data.uniqueId?.trim() ?? '';
    emailController.text = data.email?.trim() ?? '';
    phoneNumberController.text = _digitsOnlyPhone(data.mobile);
    addressController.text = data.address?.trim() ?? '';
    pincodeController.text =
        (data.pincode ?? data.zipcode)?.trim() ?? '';
    imageUrl.value = data.profileImage?.trim() ?? '';
    selectedImage.value = null;
    selectedGender.value = _normalizeGender(data.gender ?? '');
    selectedDateOfBirth.value = _parseDate(data.dateOfBirth);
    staffRole.value = data.staffRole ?? '';
    permissions.assignAll(data.permissions ?? []);
    isActivated.value = data.activated ?? true;
    outletName.value =
        appPref.selectedOutlet?.businessName?.trim() ??
        data.outletData?.firstOrNull?.businessName?.trim() ??
        '';

    locationPicker.applyInitial(
      stateName: data.state,
      cityName: data.district ?? data.city,
    );

    // Keep session user in sync with latest profile fields.
    final current = appPref.user;
    if (current != null) {
      appPref.user = User(
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
        id: current.id,
        userId: current.userId ?? data.userId,
        role: current.role ?? data.role,
        brandName: current.brandName ?? data.brandName,
        email: data.email ?? current.email,
        address: data.address ?? current.address,
        city: data.district ?? data.city ?? current.city,
        state: data.state ?? current.state,
        zipcode: data.pincode ?? data.zipcode ?? current.zipcode,
        country: current.country ?? data.country,
        firstName: name.isNotEmpty ? name : current.firstName,
        lastName: current.lastName,
        title: current.title,
        mobile: data.mobile ?? current.mobile,
        isTrial: current.isTrial,
        outletData: current.outletData ?? data.outletData,
        staffRole: data.staffRole ?? current.staffRole,
        permissions: data.permissions ?? current.permissions,
        userName: name,
        uniqueId: data.uniqueId,
        district: data.district,
        pincode: data.pincode,
        dateOfBirth: data.dateOfBirth,
        gender: data.gender,
        profileImage: data.profileImage,
        activated: data.activated,
      );
      if (data.permissions != null) {
        appPref.staffPermissions = data.permissions!;
      }
    }
  }

  void enterEditMode() => isEditMode.value = true;

  void cancelEdit() {
    isEditMode.value = false;
    loadProfile();
  }

  Future<void> pickProfileImage() async {
    final source = await Get.bottomSheet<ImageSource>(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      selectedImage.value = File(image.path);
      if (!isEditMode.value) isEditMode.value = true;
    } catch (e) {
      showError(description: 'Could not pick image. Please try again.');
    }
  }

  void removeProfileImage() {
    selectedImage.value = null;
    imageUrl.value = '';
    if (!isEditMode.value) isEditMode.value = true;
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
    if (picked != null) selectedDateOfBirth.value = picked;
  }

  Future<void> saveProfile() async {
    final staffId = appPref.user?.id;
    if (staffId == null || staffId.isEmpty) return;

    final name = userNameController.text.trim();
    final phone = phoneNumberController.text.trim();
    if (name.isEmpty) {
      showError(description: 'Please enter your name.');
      return;
    }
    if (phone.length < 10) {
      showError(description: 'Please enter a valid 10-digit phone number.');
      return;
    }

    isSaving.value = true;
    try {
      final uploaded = await _ensureImageUploaded();
      if (!uploaded) {
        showError(description: 'Failed to upload profile picture.');
        return;
      }

      final body = <String, dynamic>{
        'userName': name,
        'userPhoneNumber': '+91$phone',
        'uniqueId': uniqueIdController.text.trim(),
        'address': addressController.text.trim(),
        'state': locationPicker.selectedStateName.value?.trim() ?? '',
        'district': locationPicker.selectedCityName.value?.trim() ?? '',
        'pincode': pincodeController.text.trim(),
        'gender': selectedGender.value.trim().toLowerCase(),
        'profileImage': imageUrl.value.trim(),
      };

      final dob = selectedDateOfBirth.value;
      if (dob != null) {
        body['dateOfBirth'] = DateFormat('yyyy-MM-dd').format(dob);
      }

      final res = await callApi(
        apiClient.updateStaffProfile(staffId, body),
        showLoader: false,
      );
      if (res == null) {
        showError(description: 'Failed to update profile.');
        return;
      }

      showSuccess(description: 'Profile updated successfully.');
      isEditMode.value = false;
      await loadProfile();
    } catch (e) {
      debugPrint('Staff profile save error: $e');
      showError(description: 'Failed to update profile.');
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> _ensureImageUploaded() async {
    if (selectedImage.value == null) return true;

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

  String _digitsOnlyPhone(String? mobile) {
    final digits = (mobile ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) return digits.substring(digits.length - 10);
    return digits;
  }

  String _normalizeGender(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'male') return 'Male';
    if (g == 'female') return 'Female';
    if (g == 'other') return 'Other';
    return gender.trim();
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }
}
