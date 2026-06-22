import 'package:billkaro/config/config.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;

  const EmailVerificationDialog({super.key, required this.email});

  static const primary = Color(0xff083c6b);
  static const secondaryPrimary = Color(0xffef8819);

  static void show(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailVerificationDialog(email: email),
    );
  }

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final apiClient = Get.find<ApiClient>();
      final response = await callApi(
        apiClient.verifyAuthEmail({'email': widget.email}),
        showLoader: false,
      );

      final verified = response is Map && response['verified'] == true;
      if (verified) {
        Get.back();
        showSuccess(description: 'Email verified successfully. You can log in now.');
        Get.offAllNamed(AppRoute.login);
        return;
      }

      showError(
        description: response is Map && response['message'] != null
            ? response['message'].toString()
            : 'Email not verified yet. Please check your inbox.',
      );
    } catch (_) {
      showError(description: 'Unable to check verification status. Please try again.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendActivation() async {
    if (_isResending) return;
    setState(() => _isResending = true);

    try {
      final apiClient = Get.find<ApiClient>();
      final response = await callApi(
        apiClient.resendAuthActivation({'email': widget.email}),
        showLoader: false,
      );

      final message = response is Map && response['message'] != null
          ? response['message'].toString()
          : 'Activation email sent. Please check your inbox.';

      if (response is Map && response['verified'] == true) {
        Get.back();
        showSuccess(description: message);
        Get.offAllNamed(AppRoute.login);
        return;
      }

      showSuccess(description: message);
    } catch (_) {
      showError(description: 'Failed to resend activation email. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EmailVerificationDialog.secondaryPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 48,
                color: EmailVerificationDialog.secondaryPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: EmailVerificationDialog.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ve sent an activation link to',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: EmailVerificationDialog.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EmailVerificationDialog.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Please check your inbox and click the activation link to verify your account.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isResending ? null : _resendActivation,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EmailVerificationDialog.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _isResending ? 'Sending...' : 'Resend Email',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EmailVerificationDialog.secondaryPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _isChecking ? 'Checking...' : 'Go to Login',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
