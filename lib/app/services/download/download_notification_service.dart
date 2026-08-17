import 'dart:io';

import 'package:billkaro/app/services/notification/app_background_notification_service.dart';
import 'package:billkaro/app/services/notification/app_notification_item.dart';
import 'package:billkaro/app/services/notification/app_notification_store.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

/// Shows download progress / complete notifications (inbox + banner + OS).
///
/// Use instead of a loader dialog + [showSuccess] snackbar for file downloads.
class DownloadNotificationService {
  DownloadNotificationService._();
  static final DownloadNotificationService instance =
      DownloadNotificationService._();

  /// Stable OS notification id for invoice downloads (progress → complete).
  static const int invoiceDownloadNotificationId = 5101;

  /// Stable OS notification id for order-report Excel downloads.
  static const int orderExcelDownloadNotificationId = 5102;

  /// Stable OS notification id for order-report PDF downloads.
  static const int orderPdfDownloadNotificationId = 5103;

  /// Stable OS notification id for item-report Excel downloads.
  static const int itemExcelDownloadNotificationId = 5104;

  /// Stable OS notification id for item-report PDF downloads.
  static const int itemPdfDownloadNotificationId = 5105;

  static const int _notificationIdBase = 5000;

  /// Shows an ongoing "downloading…" notification (no loader dialog).
  Future<void> notifyProgress({
    required int notificationId,
    String title = 'Downloading',
    String body = 'Please wait…',
  }) async {
    _showInAppBanner(
      title: title,
      message: body,
      icon: Icons.downloading_rounded,
      backgroundColor: const Color(0xFF1565C0),
      duration: const Duration(seconds: 2),
    );

    await AppBackgroundNotificationService.instance.showDownloadProgress(
      notificationId: notificationId,
      title: title,
      body: body,
    );
  }

  /// Replaces the progress notification with a completed one.
  Future<void> notifyComplete({
    required String fileName,
    required String filePath,
    String title = 'Download complete',
    String? body,
    int? notificationId,
  }) async {
    final resolvedId =
        notificationId ??
        (_notificationIdBase + (filePath.hashCode.abs() % 900));
    final message = body ?? _defaultBody(fileName, filePath);

    if (Get.isRegistered<AppPref>()) {
      final pref = Get.find<AppPref>();
      if (!pref.notificationsEnabled) {
        _showInAppBanner(title: title, message: message);
        return;
      }
    }

    final itemId =
        'download_${filePath.hashCode}_${DateTime.now().millisecondsSinceEpoch}';

    if (Get.isRegistered<AppNotificationStore>()) {
      await AppNotificationStore.to.add(
        AppNotificationItem(
          id: itemId,
          type: AppNotificationType.download,
          title: title,
          body: message,
          createdAtIso: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    }

    _showInAppBanner(title: title, message: message);

    await AppBackgroundNotificationService.instance.showDownloadComplete(
      notificationId: resolvedId,
      title: title,
      body: message,
      payload: filePath,
    );

    if (!kIsWeb && Platform.isWindows) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Clears / updates the progress notification after a failure.
  Future<void> notifyFailed({
    required int notificationId,
    String title = 'Download failed',
    String body = 'Something went wrong while downloading',
  }) async {
    _showInAppBanner(
      title: title,
      message: body,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFFB71C1C),
    );

    await AppBackgroundNotificationService.instance.showDownloadComplete(
      notificationId: notificationId,
      title: title,
      body: body,
    );
  }

  String _defaultBody(String fileName, String filePath) {
    final name = fileName.trim().isNotEmpty
        ? fileName
        : p.basename(filePath);
    return '$name saved to Downloads';
  }

  void _showInAppBanner({
    required String title,
    required String message,
    IconData icon = Icons.download_done_rounded,
    Color backgroundColor = const Color(0xFF1B5E20),
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!Get.isRegistered<GetMaterialController>()) return;

    AppSnackbar.showRaw(
      backgroundColor: backgroundColor,
      snackPosition: SnackPosition.TOP,
      duration: duration,
      icon: Icon(icon, color: Colors.white),
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
