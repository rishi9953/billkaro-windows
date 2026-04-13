import 'dart:io';
import 'package:billkaro/app/services/Modals/businessType/businesst_type_response.dart';
import 'package:billkaro/app/services/Modals/registration_modal.dart';
import 'package:billkaro/app/Widgets/email_verification_dialog.dart';
import 'package:billkaro/config/config.dart';

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

  @override
  void onInit() {
    super.onInit();
    getBusinessTypes();
  }

  @override
  void onClose() {
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

  void submitRegistration() {
    // Check if form state is available
    if (formKey.currentState == null) {
      showError(description: 'Form not initialized. Please try again.');
      return;
    }

    // Validate form fields
    if (!formKey.currentState!.validate()) {
      return;
    }

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

    onSubmit();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim().toLowerCase();
    // Improved email regex pattern - more comprehensive
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    // Additional check for consecutive dots
    if (trimmed.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }
    // Check for valid domain
    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[1].isEmpty) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void onSubmit() async {
    try {
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
        title: primaryContact.value!['title']?.toString().trim() ?? '',
        mobile: '+91${primaryContact.value!['mobile']?.toString().trim()}',
      );
      debugPrint(request.toJson().toString());
      final response = await callApi(apiClient.registration(request));
      debugPrint('Api Response is : $response');
      if (response != null) {
        Get.dialog(
          barrierDismissible: false,
          EmailVerificationDialog(
            email: emailController.text.trim().toLowerCase(),
          ),
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      showError(description: 'Registration failed. Please try again.');
    }
  }
}
