import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// OS-level notifications (Android / iOS). Windows uses in-app alerts only
/// (v17 plugin has no Windows native module — avoids VS ATL build requirement).
class AppBackgroundNotificationService {
  AppBackgroundNotificationService._();
  static final AppBackgroundNotificationService instance =
      AppBackgroundNotificationService._();

  static const String kitchenChannelId = 'kitchen_bump_channel';
  static const String kitchenChannelName = 'Kitchen ready';
  static const String kitchenChannelDescription =
      'Alerts when an order is bumped from the kitchen display';

  static const String newOrderChannelId = 'new_order_channel';
  static const String newOrderChannelName = 'New orders';
  static const String newOrderChannelDescription =
      'Alerts when a new order is placed (e.g. QR menu)';

  static const String syncChannelId = 'sync_channel';
  static const String syncChannelName = 'Synchronization';

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  bool get _supportsNativePlugin =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || kIsWeb || !_supportsNativePlugin) return;

    try {
      _plugin = FlutterLocalNotificationsPlugin();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin!.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      if (Platform.isAndroid) {
        await _plugin!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                kitchenChannelId,
                kitchenChannelName,
                description: kitchenChannelDescription,
                importance: Importance.high,
                playSound: true,
              ),
            );
        await _plugin!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                syncChannelId,
                syncChannelName,
                importance: Importance.low,
                playSound: false,
              ),
            );
        await _plugin!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                newOrderChannelId,
                newOrderChannelName,
                description: newOrderChannelDescription,
                importance: Importance.high,
                playSound: true,
              ),
            );
      }
      _initialized = true;
      debugPrint('✅ [BACKGROUND NOTIFY] initialized');
    } catch (e) {
      debugPrint('❌ [BACKGROUND NOTIFY] init failed: $e');
    }
  }

  Future<void> showNewOrder({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_supportsNativePlugin) return;
    await initialize();
    if (_plugin == null) return;

    try {
      final NotificationDetails details;
      if (Platform.isAndroid) {
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            newOrderChannelId,
            newOrderChannelName,
            channelDescription: newOrderChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
        );
      } else {
        details = const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
      }

      await _plugin!.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ [BACKGROUND NOTIFY] new order show failed: $e');
    }
  }

  Future<void> showKitchenReady({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_supportsNativePlugin) return;
    await initialize();
    if (_plugin == null) return;

    try {
      final NotificationDetails details;
      if (Platform.isAndroid) {
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            kitchenChannelId,
            kitchenChannelName,
            channelDescription: kitchenChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
        );
      } else {
        details = const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
      }

      await _plugin!.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ [BACKGROUND NOTIFY] show failed: $e');
    }
  }
}
