import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_layout.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_theme.dart';
import 'package:billkaro/app/services/notification/app_notification_store.dart';
import 'package:billkaro/config/config.dart';

class SidebarNotificationIcon extends StatelessWidget {
  const SidebarNotificationIcon({
    super.key,
    required this.isSelected,
    required this.collapsed,
  });

  final bool isSelected;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? SidebarColors.textActive
        : SidebarColors.iconInactive;

    Widget buildIcon(bool active) {
      return Icon(
        active
            ? Icons.notifications_active_rounded
            : Icons.notifications_outlined,
        size: SidebarLayout.navIconSize,
        color: color,
      );
    }

    if (!Get.isRegistered<AppNotificationStore>()) {
      return buildIcon(false);
    }

    return Obx(() {
      final unread = AppNotificationStore.to.unreadCount;
      final icon = buildIcon(unread > 0);
      if (unread <= 0) return icon;
      return Badge(
        isLabelVisible: !collapsed,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          style: const TextStyle(fontSize: 9),
        ),
        child: icon,
      );
    });
  }
}
