import 'package:billkaro/app/services/notification/app_notification_item.dart';
import 'package:billkaro/app/services/notification/app_notification_store.dart';
import 'package:billkaro/config/config.dart';

class AppNotificationsController extends BaseController {
  AppNotificationStore get store => AppNotificationStore.to;

  @override
  void onReady() {
    super.onReady();
    store.load();
  }

  Future<void> markRead(String id) => store.markRead(id);

  Future<void> markAllRead() => store.markAllRead();

  Future<void> clearAll() async {
    await store.clearAll();
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(description: loc.notifications_cleared);
  }

  IconData iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.kitchenReady:
        return Icons.restaurant_menu_rounded;
      case AppNotificationType.newOrder:
        return Icons.receipt_long_rounded;
      case AppNotificationType.sync:
        return Icons.sync_rounded;
    }
  }

  Color colorFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.kitchenReady:
        return const Color(0xFF1B5E20);
      case AppNotificationType.newOrder:
        return const Color(0xFF083C6B);
      case AppNotificationType.sync:
        return AppColor.primary;
    }
  }
}
