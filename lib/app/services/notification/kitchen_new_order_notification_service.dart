import 'dart:async';
import 'dart:io';

import 'package:billkaro/app/modules/BusinessOverview/business_overview_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/services/Modals/kds/kds_order_placed_event.dart';
import 'package:billkaro/app/services/notification/app_background_notification_service.dart';
import 'package:billkaro/app/services/notification/app_notification_item.dart';
import 'package:billkaro/app/services/notification/app_notification_store.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Notifies staff when a new order is placed (e.g. QR menu).
class KitchenNewOrderNotificationService {
  KitchenNewOrderNotificationService._();
  static final KitchenNewOrderNotificationService instance =
      KitchenNewOrderNotificationService._();

  static const int _notificationIdBase = 4000;

  Future<void> notifyOrderPlaced(KdsOrderPlacedEvent event) async {
    if (!Get.isRegistered<AppPref>()) return;
    final pref = Get.find<AppPref>();
    if (!pref.notificationsEnabled) return;

    final tablePart = (event.tableNumber?.trim().isNotEmpty ?? false)
        ? 'Table ${event.tableNumber}'
        : 'Walk-in';
    final billPart = event.billNumber.trim().isNotEmpty
        ? 'Bill #${event.billNumber}'
        : event.orderId;
    final sourcePart = event.isQrMenuOrder
        ? 'QR Menu'
        : ((event.orderFrom?.trim().isNotEmpty ?? false)
            ? event.orderFrom!.trim()
            : 'New order');
    final amountPart = event.totalAmount > 0
        ? ' · ₹${event.totalAmount.toStringAsFixed(2)}'
        : '';
    final paymentPart = (event.paymentReceivedIn?.trim().isNotEmpty ?? false)
        ? ' · Paid via ${event.paymentReceivedIn!.trim().toUpperCase()}'
        : '';

    final title = event.isQrMenuOrder ? 'QR order placed' : 'New order placed';
    final message =
        '$tablePart · $billPart · $sourcePart$amountPart$paymentPart';

    final itemId = event.dedupeKey;
    if (Get.isRegistered<AppNotificationStore>()) {
      await AppNotificationStore.to.add(
        AppNotificationItem(
          id: itemId,
          type: AppNotificationType.newOrder,
          title: title,
          body: message,
          orderId: event.orderId,
          billNumber: event.billNumber,
          tableNumber: event.tableNumber,
          createdAtIso: event.placedAt.isNotEmpty
              ? event.placedAt
              : DateTime.now().toUtc().toIso8601String(),
        ),
      );
    }

    _showInAppBanner(title: title, message: message);

    await AppBackgroundNotificationService.instance.showNewOrder(
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

    _refreshOrderLists();
  }

  void _refreshOrderLists() {
    if (Get.isRegistered<HomeScreenController>()) {
      unawaited(
        Get.find<HomeScreenController>().getOrderList(forceApiRefresh: true),
      );
    }
    if (Get.isRegistered<BusinessOverviewController>()) {
      unawaited(
        Get.find<BusinessOverviewController>().getOrderList(
          forceApiRefresh: true,
        ),
      );
    }
  }

  void _showInAppBanner({required String title, required String message}) {
    if (!Get.isRegistered<GetMaterialController>()) return;

    AppSnackbar.showRaw(
      backgroundColor: const Color(0xFF083C6B),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 7),
      icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
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
