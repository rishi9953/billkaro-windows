import 'package:billkaro/config/app_colors.dart';
import 'package:billkaro/config/config.dart';
import 'package:lottie/lottie.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final String title;
  final String bodyText;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    this.title = 'Verify Your Email',
    this.bodyText =
        'Please check your inbox and click the activation link to verify your account.',
  });

  static const primary = Color(0xff083c6b);
  static const secondaryPrimary = Color(0xffef8819);
  static const _border = Color(0xffe5e7eb);
  static const _footerBg = Color(0xfff9fafb);
  static const _textSecondary = Color(0xff6b7280);

  static void show(
    BuildContext context,
    String email, {
    String title = 'Verify Your Email',
    String? bodyText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => EmailVerificationDialog(
        email: email,
        title: title,
        bodyText: bodyText ??
            'Please check your inbox and click the activation link to verify your account.',
      ),
    );
  }

  static void showIfPossible(
    String email, {
    String title = 'Account Not Activated',
    String? bodyText,
  }) {
    final context = Get.context;
    if (context == null) return;
    show(
      context,
      email,
      title: title,
      bodyText: bodyText,
    );
  }

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _isResending = false;

  void _onCancel() {
    Get.back();
    Get.offAllNamed(AppRoute.login);
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
      showError(
        description: 'Failed to resend activation email. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Widget _desktopButton({
    required String label,
    required bool loading,
    required VoidCallback? onPressed,
    required bool primary,
  }) {
    final minSize = const Size(148, 40);

    if (primary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: EmailVerificationDialog.primary,
          foregroundColor: Colors.white,
          minimumSize: minSize,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: EmailVerificationDialog.primary,
        minimumSize: minSize,
        side: const BorderSide(color: EmailVerificationDialog._border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: EmailVerificationDialog.primary,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = (screenWidth * 0.34).clamp(460.0, 560.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              decoration: const BoxDecoration(
                color: EmailVerificationDialog.primary,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Lottie.asset(
                      'assets/lottie/Verification.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Account activation required',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bodyText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: EmailVerificationDialog._textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Activation email address',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.backGroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: EmailVerificationDialog._border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 18,
                          color: EmailVerificationDialog.secondaryPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.email,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: EmailVerificationDialog.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EmailVerificationDialog.secondaryPrimary
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: EmailVerificationDialog.secondaryPrimary
                            .withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: EmailVerificationDialog.secondaryPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Click Resend Email to receive a fresh activation link, '
                            'then sign in after activating your account.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: EmailVerificationDialog._footerBg,
                border: Border(top: BorderSide(color: EmailVerificationDialog._border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _desktopButton(
                    label: 'Cancel',
                    loading: false,
                    onPressed: _isResending ? null : _onCancel,
                    primary: false,
                  ),
                  const SizedBox(width: 10),
                  _desktopButton(
                    label: _isResending ? 'Sending...' : 'Resend Email',
                    loading: _isResending,
                    onPressed: _isResending ? null : _resendActivation,
                    primary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
