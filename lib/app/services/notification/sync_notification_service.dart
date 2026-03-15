import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service to show sync progress notifications
class SyncNotificationService {
  static final SyncNotificationService _instance = SyncNotificationService._internal();
  factory SyncNotificationService() => _instance;
  SyncNotificationService._internal();

  static const int syncNotificationId = 1001;
  static const String syncChannelId = 'sync_channel';
  static const String syncChannelName = 'Synchronization';
  static const String syncChannelDescription = 'Shows synchronization progress';

  FlutterLocalNotificationsPlugin? _notifications;
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _notifications = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      _isInitialized = true;
      debugPrint('✅ [NOTIFICATION] Service initialized');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Initialization failed: $e');
    }
  }

  /// Create notification channel for Android (safe on Android 16+)
  Future<void> _createNotificationChannel() async {
    if (!_isInitialized || _notifications == null) return;

    try {
      const androidChannel = AndroidNotificationChannel(
        syncChannelId,
        syncChannelName,
        description: syncChannelDescription,
        importance: Importance.low,
        showBadge: false,
        playSound: false,
        enableVibration: false,
      );

      await _notifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] createNotificationChannel failed: $e');
    }
  }

  /// Show sync progress notification
  /// [current] - Current progress (0-100)
  /// [total] - Total items to sync
  /// [synced] - Number of items synced
  Future<void> showSyncProgress({
    required int current,
    required int total,
    required int synced,
  }) async {
    if (!_isInitialized || _notifications == null) {
      await initialize();
    }

    if (_notifications == null) return;

    try {
      final progress = total > 0 ? (current / total * 100).round() : 0;

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        syncChannelId,
        syncChannelName,
        channelDescription: syncChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        indeterminate: false,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        styleInformation: BigTextStyleInformation(
          'Syncing $synced of $total orders...',
        ),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications!.show(
        syncNotificationId,
        'Synchronizing Data',
        'Syncing $synced of $total orders...',
        notificationDetails,
      );

      debugPrint('📢 [NOTIFICATION] Progress: $progress% ($synced/$total)');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to show progress: $e');
    }
  }

  /// Show sync started notification
  Future<void> showSyncStarted({int? totalOrders}) async {
    if (!_isInitialized || _notifications == null) {
      await initialize();
    }

    if (_notifications == null) return;

    try {
      final message = totalOrders != null && totalOrders > 0
          ? 'Syncing $totalOrders orders...'
          : 'Starting synchronization...';

      final androidDetails = AndroidNotificationDetails(
        syncChannelId,
        syncChannelName,
        channelDescription: syncChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: 0,
        indeterminate: true,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        styleInformation: BigTextStyleInformation(message),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications!.show(
        syncNotificationId,
        'Synchronizing Data',
        message,
        notificationDetails,
      );

      debugPrint('📢 [NOTIFICATION] Sync started');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to show started: $e');
    }
  }

  /// Show sync completed notification
  Future<void> showSyncCompleted({
    required int syncedCount,
    required int totalCount,
    bool hasErrors = false,
  }) async {
    if (!_isInitialized || _notifications == null) return;

    try {
      final title = hasErrors
          ? 'Sync Completed with Errors'
          : 'Sync Completed Successfully';
      final message = hasErrors
          ? '$syncedCount of $totalCount orders synced'
          : 'All $syncedCount orders synced successfully';

      final androidDetails = AndroidNotificationDetails(
        syncChannelId,
        syncChannelName,
        channelDescription: syncChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showProgress: false,
        onlyAlertOnce: true,
        ongoing: false,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(message),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications!.show(
        syncNotificationId,
        title,
        message,
        notificationDetails,
      );

      debugPrint('📢 [NOTIFICATION] Sync completed: $message');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to show completed: $e');
    }
  }

  /// Show sync failed notification
  Future<void> showSyncFailed({String? errorMessage}) async {
    if (!_isInitialized || _notifications == null) return;

    try {
      final message = errorMessage ?? 'Synchronization failed. Please try again.';

      final androidDetails = AndroidNotificationDetails(
        syncChannelId,
        syncChannelName,
        channelDescription: syncChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showProgress: false,
        onlyAlertOnce: true,
        ongoing: false,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(message),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications!.show(
        syncNotificationId,
        'Sync Failed',
        message,
        notificationDetails,
      );

      debugPrint('📢 [NOTIFICATION] Sync failed: $message');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to show failed: $e');
    }
  }

  /// Cancel sync notification
  Future<void> cancelSyncNotification() async {
    if (!_isInitialized || _notifications == null) return;

    try {
      await _notifications!.cancel(syncNotificationId);
      debugPrint('📢 [NOTIFICATION] Sync notification cancelled');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to cancel: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📢 [NOTIFICATION] Tapped: ${response.payload}');
    // You can add navigation logic here if needed
  }
}

