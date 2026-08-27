import 'package:billkaro/config/config.dart';

/// Shared payment-success dialog used on wallet (and matching mobile app UI).
class PaymentSuccessDialog extends StatelessWidget {
  final String title;
  final String description;
  final String okLabel;

  const PaymentSuccessDialog({
    super.key,
    required this.title,
    required this.description,
    required this.okLabel,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String description,
    required String okLabel,
  }) {
    return Get.dialog(
      PaymentSuccessDialog(
        title: title,
        description: description,
        okLabel: okLabel,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/Success.json',
                  repeat: false,
                ),
              ),
              const Gap(8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              const Gap(10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColor.textSecondary,
                ),
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Get.back(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    okLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
