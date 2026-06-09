import 'dart:io';

import 'package:billkaro/app/services/Modals/kds/kds_bump_events_response.dart';
import 'package:billkaro/app/services/notification/app_background_notification_service.dart';
import 'package:billkaro/app/services/notification/app_notification_item.dart';
import 'package:billkaro/app/services/notification/app_notification_store.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Notifies the owner when kitchen bumps an order (web KDS or kitchen window).
class KitchenBumpNotificationService {
  KitchenBumpNotificationService._();
  static final KitchenBumpNotificationService instance =
      KitchenBumpNotificationService._();

  static const int _notificationIdBase = 3000;

  Future<void> notifyBump(KdsBumpEvent event) async {
    if (!Get.isRegistered<AppPref>()) return;
    final pref = Get.find<AppPref>();
    if (!pref.notificationsEnabled) return;

    final tablePart = (event.tableNumber?.trim().isNotEmpty ?? false)
        ? 'Table ${event.tableNumber}'
        : 'Order';
    final billPart = event.billNumber.trim().isNotEmpty
        ? 'Bill #${event.billNumber}'
        : event.orderId;
    final title = 'Kitchen ready';
    final message = '$tablePart · $billPart is ready to serve';

    final itemId = event.dedupeKey;
    if (Get.isRegistered<AppNotificationStore>()) {
      await AppNotificationStore.to.add(
        AppNotificationItem(
          id: itemId,
          type: AppNotificationType.kitchenReady,
          title: title,
          body: message,
          orderId: event.orderId,
          billNumber: event.billNumber,
          tableNumber: event.tableNumber,
          createdAtIso: event.bumpedAt.isNotEmpty
              ? event.bumpedAt
              : DateTime.now().toUtc().toIso8601String(),
        ),
      );
    }

    _showInAppBanner(title: title, message: message);

    await AppBackgroundNotificationService.instance.showKitchenReady(
      notificationId:
          _notificationIdBase + (event.orderId.hashCode.abs() % 900),
      title: title,
      body: message,
      payload: event.orderId,
    );

    if (!kIsWeb && Platform.isWindows) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  void _showInAppBanner({required String title, required String message}) {
    if (!Get.isRegistered<GetMaterialController>()) return;

    AppSnackbar.showRaw(
      backgroundColor: const Color(0xFF1B5E20),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 6),
      icon: const Icon(Icons.restaurant_menu_rounded, color: Colors.white),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
