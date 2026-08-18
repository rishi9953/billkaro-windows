import 'package:billkaro/app/modules/InternetSpeed/internet_speed_controller.dart';
import 'package:billkaro/app/modules/InternetSpeed/widgets/internet_speed_test_dialog.dart';
import 'package:billkaro/config/config.dart';

class InternetSpeedAppBarButton extends StatelessWidget {
  const InternetSpeedAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final color = Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    InternetSpeedController.ensure();

    return Tooltip(
      message: loc.internet_speed_tap_to_test,
      child: IconButton(
        onPressed: () => showInternetSpeedTestDialog(context),
        icon: Obx(() {
          final controller = InternetSpeedController.ensure();
          controller.phase.value;
          if (controller.isRunning) {
            return SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            );
          }
          return Icon(Icons.speed_rounded, color: color, size: 24);
        }),
      ),
    );
  }
}
