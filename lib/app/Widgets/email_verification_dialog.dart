import 'package:billkaro/config/config.dart';

class EmailVerificationDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: secondaryPrimary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.email_outlined, size: 48, color: secondaryPrimary),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Verify Your Email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'We\'ve sent an activation link to',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              email,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Please check your inbox and click the activation link to verify your account.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offAllNamed(AppRoute.main);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Got it', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
