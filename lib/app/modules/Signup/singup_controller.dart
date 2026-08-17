import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:billkaro/app/services/Modals/businessType/businesst_type_response.dart';
import 'package:billkaro/app/services/Modals/registration_modal.dart';
import 'package:billkaro/app/services/Network/api_config.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/trusted_http_client.dart';

class SignupController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final businessNameController = TextEditingController();
  final brandNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final selectedBusinessType = 'retail'.obs;
  final businessAddress = Rxn<Map<String, dynamic>>();
  final primaryContact = Rxn<Map<String, dynamic>>();
  var isPasswordVisible = false.obs;

  final businessTypesList = <BusinessType>[].obs;

  Timer? _emailCheckDebounce;
  final isEmailChecking = false.obs;
  final isEmailAvailable = Rxn<bool>();
  final emailVerificationError = RxnString();
  String? _lastCheckedEmail;
  final isSubmitting = false.obs;

  String _normalizeContactTitle(String? title) {
    final normalized = title?.toString().trim() ?? '';
    if (normalized.toLowerCase() == 'other') return 'other';
    return normalized;
  }

  Future<void> _showAccountActivationDialog(String registeredEmail) async {
    await Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: AppColor.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Account activation required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Your account has been registered successfully.\n\n'
          'Please activate your account using the email sent to:\n'
          '$registeredEmail',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static const List<String> _fallbackBusinessTypes = [
    'retail',
    'service',
    'manufacturing',
    'other',
  ];

  List<({String display, String value})> get businessTypeOptions {
    if (businessTypesList.isNotEmpty) {
      return businessTypesList
          .map((e) => (display: e.name, value: e.value))
          .toList();
    }
    return _fallbackBusinessTypes
        .map((e) => (display: e.capitalizeFirst!, value: e))
        .toList();
  }

  String get selectedBusinessTypeLabel {
    final selectedValue = selectedBusinessType.value.trim().toLowerCase();
    for (final option in businessTypeOptions) {
      if (option.value.trim().toLowerCase() == selectedValue) {
        return option.display;
      }
    }
    return selectedValue.isEmpty
        ? _fallbackBusinessTypes.first.capitalizeFirst!
        : selectedValue.capitalizeFirst ?? selectedValue;
  }

  @override
  void onInit() {
    super.onInit();
    getBusinessTypes();
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

    if (trimmed == _lastCheckedEmail) return;

    _emailCheckDebounce?.cancel();
    isEmailAvailable.value = null;
    isEmailChecking.value = true;

    _emailCheckDebounce = Timer(const Duration(milliseconds: 600), () {
      checkEmailAvailability(trimmed);
    });
  }

  Future<Map<String, dynamic>?> _requestEmailAvailability(String email) async {
    final response = await callApi(
      apiClient.checkAuthEmail({'email': email}),
      showLoader: false,
      apiErrorHandler: (_) async => true,
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}auth/check-email');
      final httpResponse = await trustedHttpClient().post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        final decoded = jsonDecode(httpResponse.body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('Email availability HTTP fallback failed: $e');
    }

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

    isEmailChecking.value = true;
    emailVerificationError.value = null;
    try {
      final response = await _requestEmailAvailability(normalizedEmail);

      if (emailController.text.trim().toLowerCase() != normalizedEmail) {
        return false;
      }

      if (response == null) {
        isEmailAvailable.value = null;
        _lastCheckedEmail = null;
        emailVerificationError.value =
            'Could not verify email right now. You can still continue registration.';
        return false;
      }

      _lastCheckedEmail = normalizedEmail;

      if (response['available'] == true) {
        isEmailAvailable.value = true;
        emailVerificationError.value = null;
        formKey.currentState?.validate();
        return true;
      }

      if (response['available'] == false) {
        isEmailAvailable.value = false;
        emailVerificationError.value = null;
        formKey.currentState?.validate();
        return false;
      }

      isEmailAvailable.value = null;
      emailVerificationError.value =
          'Could not verify email right now. You can still continue registration.';
      return false;
    } catch (_) {
      if (emailController.text.trim().toLowerCase() == normalizedEmail) {
        isEmailAvailable.value = null;
        _lastCheckedEmail = null;
        emailVerificationError.value =
            'Could not verify email right now. You can still continue registration.';
      }
      return false;
    } finally {
      if (emailController.text.trim().toLowerCase() == normalizedEmail) {
        isEmailChecking.value = false;
      }
    }
  }

  @override
  void onClose() {
    _emailCheckDebounce?.cancel();
    businessNameController.dispose();
    brandNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void getBusinessTypes() async {
    final response = await callApi(
      apiClient.getBusinessTypes(true),
      showLoader: false,
    );
    if (response != null && response.status == 'success') {
      businessTypesList.value = response.data;
    }
  }

  void showBusinessTypeDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(Get.context!).size.width * 0.35,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Business Type',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(),
                const SizedBox(height: 8),

                // Business type options
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(Get.context!).size.height * 0.5,
                  ),
                  child: Obx(
                    () => SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: businessTypeOptions.map((opt) {
                          return InkWell(
                            onTap: () {
                              selectedBusinessType.value = opt.value;
                              Get.back();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: selectedBusinessType.value == opt.value
                                    ? AppColor.primary.withOpacity(0.1)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedBusinessType.value == opt.value
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color:
                                        selectedBusinessType.value == opt.value
                                        ? AppColor.primary
                                        : Colors.grey,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      opt.display,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            selectedBusinessType.value ==
                                                opt.value
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> selectAddress() async {
    final result = await Get.toNamed(AppRoute.addAddress);
    if (result != null && result is Map<String, dynamic>) {
      businessAddress.value = result;
    }
  }

  Future<void> selectPrimaryContact() async {
    final result = await Get.toNamed(AppRoute.primaryContact);
    if (result != null && result is Map<String, dynamic>) {
      primaryContact.value = result;
    }
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateBusinessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Business name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Business name must not exceed 100 characters';
    }
    return null;
  }

  String? validateBrandName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Brand name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Brand name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Brand name must not exceed 100 characters';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (value.length > 50) {
      return 'Password must not exceed 50 characters';
    }
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  void submitRegistration() async {
    // Check if form state is available
    if (formKey.currentState == null) {
      showError(description: 'Form not initialized. Please try again.');
      return;
    }

    // Validate form fields
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim().toLowerCase();
    if (isEmailChecking.value) {
      showError(description: 'Please wait while we verify your email.');
      return;
    }

    if (_lastCheckedEmail != email || isEmailAvailable.value == false) {
      await checkEmailAvailability(email);
    }

    if (isEmailAvailable.value == false) {
      showError(
        description:
            'This email is already registered. Please use a different email.',
      );
      return;
    }

    // If live check is inconclusive (network/TLS), allow submit — register API validates.

    // Validate address
    if (businessAddress.value == null) {
      showError(description: 'Please add business address');
      return;
    }

    // Validate contact
    if (primaryContact.value == null) {
      showError(description: 'Please add primary contact');
      return;
    }

    // Validate address fields are complete
    final address = businessAddress.value!;
    if (address['address'] == null ||
        address['address'].toString().trim().isEmpty ||
        address['city'] == null ||
        address['city'].toString().trim().isEmpty ||
        address['state'] == null ||
        address['state'].toString().trim().isEmpty) {
      showError(description: 'Please complete all address fields');
      return;
    }

    // Validate contact fields are complete
    final contact = primaryContact.value!;
    if (contact['firstName'] == null ||
        contact['firstName'].toString().trim().isEmpty ||
        contact['mobile'] == null ||
        contact['mobile'].toString().trim().isEmpty) {
      showError(description: 'Please complete all contact fields');
      return;
    }

    final mobile = contact['mobile'].toString().replaceAll(RegExp(r'[^\d]'), '');
    final mobileAvailable = await checkMobileAvailability(mobile);
    if (mobileAvailable == false) {
      showError(
        description:
            'This mobile number is already registered. Please use a different number.',
      );
      return;
    }

    final confirmed = await showRegistrationConfirmationDialog();
    if (!confirmed) return;

    await onSubmit();
  }

  Future<bool> checkMobileAvailability(String mobile) async {
    final digits = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return false;
    }

    try {
      final response = await callApi(
        apiClient.checkAuthMobile({'mobile': digits}),
        showLoader: false,
        apiErrorHandler: (_) async => true,
      );

      if (response is Map && response['available'] == false) {
        return false;
      }

      if (response is Map && response['available'] == true) {
        return true;
      }
    } catch (_) {
      // Allow submit — register API validates.
    }

    return true;
  }

  String? _emailFormatError(String trimmed) {
    if (trimmed.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    if (trimmed.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }
    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[1].isEmpty) {
      return 'Please enter a valid email address';
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

  //clear Form

  Future<bool> showRegistrationConfirmationDialog() async {
    final businessName = businessNameController.text.trim();
    final brandName = brandNameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final businessType = selectedBusinessTypeLabel;
    final address = businessAddress.value ?? {};
    final contact = primaryContact.value ?? {};
    final addressLine =
        '${address['address'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''}'
            .trim();
    final contactName =
        '${contact['firstName'] ?? ''} ${contact['lastName'] ?? ''}'.trim();
    final contactMobile = contact['mobile']?.toString().trim() ?? '';

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppColor.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Confirm registration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please review your details before creating the account.',
                style: TextStyle(fontSize: 13.5, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              _confirmationRow('Business', businessName),
              _confirmationRow('Brand', brandName),
              _confirmationRow('Email', email),
              _confirmationRow('Type', businessType),
              _confirmationRow('Address', addressLine),
              _confirmationRow(
                'Primary contact',
                '$contactName${contactMobile.isNotEmpty ? ' - $contactMobile' : ''}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Edit details'),
          ),
          ElevatedButton.icon(
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirm & Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    return result == true;
  }

  Widget _confirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onSubmit() async {
    if (isSubmitting.value) return;

    try {
      isSubmitting.value = true;
      HttpOverrides.global = MyHttpOverrides();

      // Trim all text inputs before submission
      var request = RegistrationModel(
        businessName: businessNameController.text.trim(),
        brandName: brandNameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
        businessType: selectedBusinessType.value,
        address: businessAddress.value!['address']?.toString().trim() ?? '',
        city: businessAddress.value!['city']?.toString().trim() ?? '',
        state: businessAddress.value!['state']?.toString().trim() ?? '',
        zipcode: businessAddress.value!['zipcode']?.toString().trim() ?? '',
        country: businessAddress.value!['country']?.toString().trim() ?? '',
        firstName: primaryContact.value!['firstName']?.toString().trim() ?? '',
        lastName: primaryContact.value!['lastName']?.toString().trim() ?? '',
        title: _normalizeContactTitle(primaryContact.value!['title']),
        mobile: '+91${primaryContact.value!['mobile']?.toString().trim()}',
      );
      debugPrint(request.toJson().toString());
      final response = await callApi(apiClient.registration(request));
      debugPrint('Api Response is : $response');
      if (response != null) {
        final registeredEmail = emailController.text.trim().toLowerCase();
        await _showAccountActivationDialog(registeredEmail);
        clearForm();
        Get.offAllNamed(AppRoute.login);
      }
    } catch (e) {
      print('Error during registration: $e');
      showError(description: 'Registration failed. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  }

  //clearForm
  void clearForm() {
    // Clear text fields
    businessNameController.clear();
    brandNameController.clear();
    emailController.clear();
    passwordController.clear();

    // Reset selections
    selectedBusinessType.value = 'retail';

    // Clear address & contact
    businessAddress.value = null;
    primaryContact.value = null;

    // Reset email validation
    isEmailChecking.value = false;
    isEmailAvailable.value = null;
    emailVerificationError.value = null;
    _lastCheckedEmail = null;

    // Reset password visibility
    isPasswordVisible.value = false;

    // Clear form validation errors
    formKey.currentState?.reset();
  }
}
