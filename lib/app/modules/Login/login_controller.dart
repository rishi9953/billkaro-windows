import 'dart:io';
import 'package:billkaro/app/services/Modals/login_modal.dart';
import 'package:billkaro/config/config.dart';

class LoginController extends BaseController {
  // Observable variables
  var toggle = true.obs;
  var isLoading = false.obs;
  var obscurePassword = true.obs;

  // Text editing controllers for Add Device form
  final registrationKeyController = TextEditingController();
  final deviceLabelController = TextEditingController();

  // Text editing controllers for Request Key form
  final accountNumberController = TextEditingController();
  final emailOrPhoneController = TextEditingController();

  // Form keys for validation
  final addDeviceFormKey = GlobalKey<FormState>();
  final requestKeyFormKey = GlobalKey<FormState>();

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    registrationKeyController.dispose();
    deviceLabelController.dispose();
    accountNumberController.dispose();
    emailOrPhoneController.dispose();
    super.onClose();
  }

  void onToggle() {
    toggle.value = !toggle.value;
    // Clear fields when switching forms
    clearAllFields();
  }

  void clearAllFields() {
    registrationKeyController.clear();
    deviceLabelController.clear();
    accountNumberController.clear();
    emailOrPhoneController.clear();
  }

  // Validation methods
  String? validateRegistrationKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validateDeviceLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 3) {
      return 'Password must be at least 3 characters';
    }
    return null;
  }

  String? validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter account number';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Account number must contain only digits';
    }
    return null;
  }

  String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email or phone number';
    }

    // Check if it's an email
    bool isEmail = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);

    // Check if it's a phone number (basic validation)
    bool isPhone = RegExp(
      r'^[0-9]{10,15}$',
    ).hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''));

    if (!isEmail && !isPhone) {
      return 'Please enter a valid email or phone number';
    }

    return null;
  }

  // Add Device functionality
  Future<void> onAddDevice() async {
    if (!addDeviceFormKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      // String registrationKey = registrationKeyController.text.trim();
      // String deviceLabel = deviceLabelController.text.trim();
      await Future.delayed(Duration(seconds: 2)); // Simulating API call

      // Simulate API response
      // bool success = true; // Replace with actual API response

      showSuccess(description: 'Device added successfully');
      // Clear the form
      clearAllFields();

      // Navigate to home or dashboard
      // Get.offAllNamed('/home');
    } catch (e) {
      showError(
        description:
            'Failed to add device. Please check your registration key and try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Forgot Password functionality
  Future<void> onRequestRegistrationKey() async {
    if (!requestKeyFormKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      final email = emailOrPhoneController.text.trim();

      // Call forgot password API
      final response = await callApi(
        apiClient.forgotPassword({'email': email}),
      );

      if (response != null) {
        // Show success dialog
        await _showForgotPasswordSuccessDialog(email);

        // Clear the form
        clearAllFields();

        // Switch back to login form
        toggle.value = true;
      } else {
        // Show error dialog if API call failed
        _showForgotPasswordErrorDialog(
          'Failed to send reset link. Please check your email and try again.',
        );
      }
    } catch (e) {
      debugPrint('Forgot password error: $e');
      _showForgotPasswordErrorDialog(
        'An error occurred. Please try again later.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onLogin() async {
    // Set up SSL bypass (call once, preferably in main())
    HttpOverrides.global = MyHttpOverrides();

    try {
      var request = LoginModel(
        email: registrationKeyController.text,
        password: deviceLabelController.text,
      );

      final response = await callApi(apiClient.onLogin(request));
      debugPrint('Login Response: $response');
      if (response != null) {
        appPref.token = response.accessToken;
        appPref.user = response.user;
        appPref.selectedOutlet = response.user.outletData![0];
        Get.offAllNamed(AppRoute.homeMain);
      }
    } catch (e) {
      print('Error during login: $e');
    }
  }

  // Show success dialog for forgot password
  Future<void> _showForgotPasswordSuccessDialog(String email) async {
    final context = Get.context;
    if (context == null) return;

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Lottie Animation
              SizedBox(
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/Success.json',
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Check Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ve sent password reset instructions to:\n$email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff083c6b),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got It',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Show error dialog for forgot password
  Future<void> _showForgotPasswordErrorDialog(String message) async {
    final context = Get.context;
    if (context == null) return;

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Lottie Animation
              SizedBox(
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/Fail.json',
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to Send Reset Link',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
