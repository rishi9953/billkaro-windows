import 'dart:async';

import 'package:billkaro/app/Widgets/email_verification_dialog.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/app/services/kds/kds_realtime_service.dart';
import 'package:billkaro/app/services/notification/app_notification_store.dart';
import 'package:billkaro/app/services/notification/kitchen_bump_monitor.dart';
import 'package:billkaro/app/services/notification/kitchen_new_order_monitor.dart';
import 'package:billkaro/app/services/session/session_realtime_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:dio/dio.dart';

class AuthSessionService {
  AuthSessionService._();

  static bool _isClearing = false;

  static const String _activationBodyText =
      'Your account is not active. Tap Resend Email to receive a new activation link on your registered email address.';

  static Future<void> clearSessionData() async {
    if (_isClearing) return;
    _isClearing = true;
    try {
      KitchenBumpMonitor.instance.stop();
      KitchenNewOrderMonitor.instance.stop();
      KdsRealtimeService.instance.disconnect();
      SessionRealtimeService.instance.disconnect();

      if (Get.isRegistered<AppNotificationStore>()) {
        unawaited(AppNotificationStore.to.clearAll());
      }

      final appPref = Get.find<AppPref>();
      appPref.token = '';

      final db = AppDatabase();
      await db.clearAllData();
      await appPref.clearAllData();
      await ThemeController.resetAfterLogout();
    } finally {
      _isClearing = false;
    }
  }

  static Future<void> performForcedLogout({
    required String message,
    String? email,
    bool canResendActivation = false,
  }) async {
    final resolvedEmail =
        email?.trim().isNotEmpty == true
            ? email!.trim()
            : (Get.isRegistered<AppPref>()
                ? Get.find<AppPref>().user?.email?.trim()
                : null);

    await clearSessionData();

    if (canResendActivation &&
        resolvedEmail != null &&
        resolvedEmail.isNotEmpty) {
      EmailVerificationDialog.showIfPossible(
        resolvedEmail,
        title: 'Account Not Activated',
        bodyText: message.isNotEmpty ? message : _activationBodyText,
      );
      return;
    }

    await _showForcedLogoutDialog(message);
  }

  static bool isAccountNotActivatedError(DioException error) {
    final message = _extractErrorMessage(error);
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains('not activated') || lower.contains('deactivated');
  }

  static String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return error.message;
  }

  static void showActivationDialogForEmail(String email) {
    EmailVerificationDialog.showIfPossible(
      email,
      title: 'Account Not Activated',
      bodyText: _activationBodyText,
    );
  }

  static Future<void> _showForcedLogoutDialog(String message) async {
    try {
      await Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account Deactivated',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.offAllNamed(AppRoute.main);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
      );
    } catch (e) {
      debugPrint('Error showing forced logout dialog: $e');
      Get.offAllNamed(AppRoute.main);
    }
  }
}
