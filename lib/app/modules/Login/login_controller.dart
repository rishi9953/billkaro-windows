import 'package:billkaro/app/services/Modals/login_modal.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_outlet_sync.dart';
import 'dart:async';

class LoginController extends BaseController {
  /// 0 = business user (auth/login), 1 = staff (auth/staff/login).
  var signInTabIndex = 0.obs;

  /// 0 = email & password, 1 = phone number (UI only).
  var loginMethodTabIndex = 0.obs;

  /// Phone OTP step: false = enter phone, true = enter OTP.
  var phoneOtpSent = false.obs;
  var otpResendSeconds = 0.obs;

  /// Locked when OTP is sent — mirrors staff vs user tab at send time.
  var otpIsStaffSession = false.obs;

  // Observable variables
  var toggle = true.obs;
  var isLoading = false.obs;
  var obscurePassword = true.obs;

  // Text editing controllers for Add Device form
  final registrationKeyController = TextEditingController();
  final deviceLabelController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final otpController = TextEditingController();

  Timer? _otpResendTimer;

  // Text editing controllers for Request Key form
  final accountNumberController = TextEditingController();
  final emailOrPhoneController = TextEditingController();

  // Form keys for validation
  final addDeviceFormKey = GlobalKey<FormState>();
  final requestKeyFormKey = GlobalKey<FormState>();

  @override
  void onClose() {
    _otpResendTimer?.cancel();
    // Dispose controllers to prevent memory leaks
    registrationKeyController.dispose();
    deviceLabelController.dispose();
    phoneNumberController.dispose();
    otpController.dispose();
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
    phoneNumberController.clear();
    otpController.clear();
    accountNumberController.clear();
    emailOrPhoneController.clear();
    phoneOtpSent.value = false;
    otpResendSeconds.value = 0;
    otpIsStaffSession.value = false;
    _otpResendTimer?.cancel();
  }

  String get fullPhoneNumber {
    final digits = phoneNumberController.text.trim().replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (digits.length >= 10) {
      final last10 = digits.length > 10
          ? digits.substring(digits.length - 10)
          : digits;
      return '+91$last10';
    }
    return digits;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  void _startOtpResendTimer() {
    _otpResendTimer?.cancel();
    otpResendSeconds.value = 60;
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpResendSeconds.value <= 1) {
        otpResendSeconds.value = 0;
        timer.cancel();
      } else {
        otpResendSeconds.value -= 1;
      }
    });
  }

  Future<void> onSendPhoneOtp({bool isResend = false}) async {
    if (isResend) {
      if (validatePhoneNumber(phoneNumberController.text) != null) {
        return;
      }
    } else if (!addDeviceFormKey.currentState!.validate()) {
      return;
    }

    final isStaff = signInTabIndex.value == 1;
    otpIsStaffSession.value = isStaff;

    try {
      isLoading.value = true;
      final phone = fullPhoneNumber;
      final response = await callApi(
        isStaff
            ? apiClient.sendStaffPhoneOtp({'phone': phone})
            : apiClient.sendPhoneOtp({'phone': phone}),
        showLoader: false,
      );

      if (response == null) {
        showError(description: 'Failed to send OTP. Please try again.');
        return;
      }

      phoneOtpSent.value = true;
      otpController.clear();
      _startOtpResendTimer();
      showSuccess(description: 'OTP sent to $phone');
    } catch (e) {
      debugPrint('Send OTP error: $e');
      showError(
        description:
            'Failed to send OTP. Please check your phone number and try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onVerifyPhoneOtp() async {
    if (!addDeviceFormKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;
      final isStaff = otpIsStaffSession.value;
      final response = await callApi(
        isStaff
            ? apiClient.verifyStaffPhoneOtp({
                'phone': fullPhoneNumber,
                'otp': otpController.text.trim(),
              })
            : apiClient.verifyPhoneOtp({
                'phone': fullPhoneNumber,
                'otp': otpController.text.trim(),
              }),
        showLoader: false,
      );

      debugPrint('Phone OTP login response: $response');
      if (response == null) {
        showError(description: 'Invalid OTP. Please try again.');
        return;
      }

      await _completeLogin(response, isStaff: isStaff);
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      showError(description: 'Invalid OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void onChangePhoneNumber() {
    phoneOtpSent.value = false;
    otpController.clear();
    otpResendSeconds.value = 0;
    _otpResendTimer?.cancel();
  }

  void onSignInTabChanged(int index) {
    signInTabIndex.value = index;
    phoneNumberController.clear();
    onChangePhoneNumber();
    otpIsStaffSession.value = index == 1;
  }

  // Validation methods
  String? validateRegistrationKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validateDeviceLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    // if (value.length < 8) {
    //   return 'Password must be at least 8 characters';
    // }
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

  // Add Device functionality (not yet wired to backend)
  Future<void> onAddDevice() async {
    showError(
      description:
          'Device registration is not available yet. Please sign in with your email and password.',
    );
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
    if (!addDeviceFormKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;
      final isStaff = signInTabIndex.value == 1;
      var request = LoginModel(
        email: registrationKeyController.text.trim(),
        password: deviceLabelController.text,
      );

      final response = await callApi(
        isStaff ? apiClient.onStaffLogin(request) : apiClient.onLogin(request),
        showLoader: false,
      );
      debugPrint('Login Response: $response');
      if (response == null) {
        showError(
          description:
              'Login failed. Please check your credentials and try again.',
        );
        return;
      }

      await _completeLogin(response, isStaff: isStaff);
    } catch (e) {
      debugPrint('Error during login: $e');
      showError(
        description:
            'Login failed. Please check your credentials and try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _completeLogin(
    LoginResponse response, {
    required bool isStaff,
  }) async {
    final roleIsStaff = response.user.role == 'staff';
    if (isStaff && !roleIsStaff) {
      showError(
        description: 'No activated staff account found for this phone number.',
      );
      return;
    }

    appPref.token = response.accessToken;
    appPref.isStaffSession = roleIsStaff;
    appPref.user = response.user;
    appPref.staffPermissions = response.user.permissions ?? [];

    final outlets = response.user.outletData;
    if (outlets == null || outlets.isEmpty) {
      showError(
        description:
            'No outlet is linked to this account. Please contact support or complete outlet setup.',
      );
      return;
    }

    appPref.selectedOutlet = outlets.first;
    if (roleIsStaff) {
      await StaffOutletSync.enrichAppPrefFromOwner(
        appPref: appPref,
        staffUser: response.user,
        apiClient: apiClient,
      );
    }
    Get.offAllNamed(AppRoute.homeMain);
  }

  // Show success dialog for forgot password
  Future<void> _showForgotPasswordSuccessDialog(String email) async {
    final context = Get.context;
    if (context == null) return;

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.3,
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Lottie Animation
              SizedBox(
                height: 140,
                child: Lottie.asset('assets/lottie/Fail.json', repeat: false),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to Send Reset Link',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
