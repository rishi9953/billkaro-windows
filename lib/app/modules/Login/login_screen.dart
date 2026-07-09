import 'dart:io';

import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/modules/Login/login_controller.dart';
import 'package:billkaro/config/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final controller = Get.put(LoginController());

  static const _primary = Color(0xff083c6b);
  static const _accent = Color(0xffef8819);
  static const _surface = Colors.white;
  static const _textPrimary = Color(0xff1a1a1a);
  static const _textSecondary = Color(0xff6b7280);
  static const _border = Color(0xffe5e7eb);

  @override
  Widget build(BuildContext context) {
    final showWindowsTitleBar = !kIsWeb && Platform.isWindows;
    final appBar = AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColor.backGroundColor,
      iconTheme: const IconThemeData(color: _textPrimary),
      title: Text(
        'Sign in',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final scrollContent = Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.toggle.value) ...[
                  _buildSignInTabs(),
                  const SizedBox(height: 16),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: controller.toggle.value
                      ? _buildLoginCard()
                      : _buildRequestKeyCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!showWindowsTitleBar) {
      return Scaffold(
        backgroundColor: AppColor.backGroundColor,
        appBar: appBar,
        body: SafeArea(child: scrollContent),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WindowsDesktopTitleBar(actions: []),
          appBar,
          Expanded(child: SafeArea(top: false, child: scrollContent)),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      key: const ValueKey('login'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: controller.addDeviceFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Lottie.asset(
              'assets/lottie/addproduct.json',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Obx(
              () => Text(
                controller.signInTabIndex.value == 1
                    ? 'Staff sign in'
                    : 'Sign in to your account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Obx(
              () => Text(
                controller.signInTabIndex.value == 1
                    ? controller.loginMethodTabIndex.value == 1
                          ? 'Enter your registered staff phone number to receive an OTP.'
                          : 'Use the email and password provided by your outlet.'
                    : controller.loginMethodTabIndex.value == 1
                    ? 'Enter your phone number to continue.'
                    : 'Enter your email and password to continue.',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLoginMethodTabs(),
            const SizedBox(height: 24),
            Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: controller.loginMethodTabIndex.value == 0
                    ? _buildEmailPasswordSignIn()
                    : _buildPhoneSignIn(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginMethodTabs() {
    return Obx(
      () => SegmentedButton<int>(
        segments: const [
          ButtonSegment<int>(
            value: 0,
            label: Text(
              'Email &\npassword',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.15),
            ),
            icon: Icon(Icons.mail_outline_rounded, size: 18),
          ),
          ButtonSegment<int>(
            value: 1,
            label: Text(
              'Phone\nnumber',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.15),
            ),
            icon: Icon(Icons.phone_outlined, size: 18),
          ),
        ],
        selected: {controller.loginMethodTabIndex.value},
        onSelectionChanged: controller.isLoading.value
            ? null
            : (Set<int> next) {
                if (next.isEmpty) return;
                controller.loginMethodTabIndex.value = next.first;
                controller.onChangePhoneNumber();
              },
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return _textPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primary;
            }
            return const Color(0xfff9fafb);
          }),
        ),
      ),
    );
  }

  Widget _buildEmailPasswordSignIn() {
    return Column(
      key: const ValueKey('emailSignIn'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          label: 'Email',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          controller: controller.registrationKeyController,
          validator: controller.validateRegistrationKey,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: 'Password',
          hint: 'Enter your password',
          controller: controller.deviceLabelController,
          validator: controller.validateDeviceLabel,
          obscureRx: controller.obscurePassword,
        ),
        const SizedBox(height: 28),
        Obx(
          () => _buildPrimaryButton(
            onPressed: () => controller.onLogin(),
            isLoading: controller.isLoading.value,
            label: 'Sign in',
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (controller.signInTabIndex.value == 1) {
            return const SizedBox.shrink();
          }
          return Center(
            child: TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.onToggle,
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhoneSignIn() {
    return Obx(
      () => Column(
        key: const ValueKey('phoneSignIn'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'Phone number',
            hint: '10-digit mobile number',
            icon: Icons.phone_outlined,
            controller: controller.phoneNumberController,
            validator: controller.validatePhoneNumber,
            keyboardType: TextInputType.phone,
            readOnly: controller.phoneOtpSent.value,
            maxLength: 10,
          ),
          if (controller.phoneOtpSent.value) ...[
            const SizedBox(height: 20),
            _buildTextField(
              label: 'OTP',
              hint: 'Enter 6-digit OTP',
              icon: Icons.lock_outline_rounded,
              controller: controller.otpController,
              validator: controller.validateOtp,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.onChangePhoneNumber,
                  child: const Text('Change number'),
                ),
                TextButton(
                  onPressed:
                      controller.isLoading.value ||
                          controller.otpResendSeconds.value > 0
                      ? null
                      : () => controller.onSendPhoneOtp(isResend: true),
                  child: Text(
                    controller.otpResendSeconds.value > 0
                        ? 'Resend in ${controller.otpResendSeconds.value}s'
                        : 'Resend OTP',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          _buildPrimaryButton(
            onPressed: () {
              if (controller.phoneOtpSent.value) {
                controller.onVerifyPhoneOtp();
              } else {
                controller.onSendPhoneOtp();
              }
            },
            //  controller.phoneOtpSent.value
            //     ? controller.onVerifyPhoneOtp
            //     : controller.onSendPhoneOtp,
            isLoading: controller.isLoading.value,
            label: controller.phoneOtpSent.value
                ? 'Verify & sign in'
                : 'Send OTP',
          ),
        ],
      ),
    );
  }

  Widget _buildSignInTabs() {
    return Obx(
      () => SegmentedButton<int>(
        segments: const [
          ButtonSegment<int>(
            value: 0,
            label: Text(
              'Sign in as\nuser',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.15),
            ),
            icon: Icon(Icons.person_outline_rounded, size: 18),
          ),
          ButtonSegment<int>(
            value: 1,
            label: Text(
              'Sign in as\nstaff',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.15),
            ),
            icon: Icon(Icons.badge_outlined, size: 18),
          ),
        ],
        selected: {controller.signInTabIndex.value},
        onSelectionChanged: controller.isLoading.value
            ? null
            : (Set<int> next) {
                if (next.isEmpty) return;
                controller.onSignInTabChanged(next.first);
              },
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return _textPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primary;
            }
            return const Color(0xfff9fafb);
          }),
        ),
      ),
    );
  }

  Widget _buildRequestKeyCard() {
    return Container(
      key: const ValueKey('requestKey'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: controller.requestKeyFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Lottie.asset(
              'assets/lottie/Verification.json',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            _buildTextField(
              label: 'Email address',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              controller: controller.emailOrPhoneController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!GetUtils.isEmail(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 28),
            Obx(
              () => _buildPrimaryButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.onRequestRegistrationKey,
                isLoading: controller.isLoading.value,
                label: 'Send reset link',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.onToggle,
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Remember your password? Sign in',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLength: maxLength,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textSecondary.withOpacity(0.8),
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, size: 22, color: _textSecondary),
            filled: true,
            fillColor: const Color(0xfff9fafb),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
            errorStyle: TextStyle(color: _accent, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    required RxBool obscureRx,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureRx.value,
            style: const TextStyle(color: _textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textSecondary.withOpacity(0.8),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: 22,
                color: _textSecondary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureRx.value
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 22,
                  color: _textSecondary,
                ),
                onPressed: () => obscureRx.value = !obscureRx.value,
                tooltip: obscureRx.value ? 'Show password' : 'Hide password',
              ),
              filled: true,
              fillColor: const Color(0xfff9fafb),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
              errorStyle: TextStyle(color: _accent, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withOpacity(0.5),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
