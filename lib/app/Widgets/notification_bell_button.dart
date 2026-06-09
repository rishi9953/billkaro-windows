import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/notification/app_notification_store.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// App bar bell with unread badge → notifications screen.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.iconColor,
    this.iconSize = 22,
    this.padding,
  });

  final Color? iconColor;
  final double iconSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AppNotificationStore>()) {
      return IconButton(
        padding: padding,
        onPressed: () => Modular.to.pushNamed(HomeMainRoutes.notifications),
        icon: Icon(
          Icons.notifications_outlined,
          size: iconSize,
          color: iconColor ?? Colors.white70,
        ),
      );
    }

    return Obx(() {
      final unread = AppNotificationStore.to.unreadCount;
      return IconButton(
        padding: padding,
        tooltip: 'Notifications',
        onPressed: () => Modular.to.pushNamed(HomeMainRoutes.notifications),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(
            unread > 99 ? '99+' : '$unread',
            style: const TextStyle(fontSize: 10),
          ),
          child: Icon(
            unread > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_outlined,
            size: iconSize,
            color: iconColor ?? Colors.white70,
          ),
        ),
      );
    });
  }
}
