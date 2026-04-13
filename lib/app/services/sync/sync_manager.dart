import 'dart:async';
import 'dart:io' show Platform;
import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Synchronisatioin/synchronisation.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/app/services/Network/network_module.dart';
import 'package:billkaro/app/services/notification/sync_notification_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';

/// Sync Manager - Coordinates all synchronization activities
/// Handles WorkManager tasks, connectivity changes, and manual sync triggers
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final AppDatabase _db = AppDatabase();
  final SyncNotificationService _notificationService = SyncNotificationService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _retryTimer;
  Timer? _foregroundPeriodicTimer;

  /// Unique task names for WorkManager
  static const String periodicSyncTask = 'periodicSyncTask';
  static const String connectivitySyncTask = 'connectivitySyncTask';
  static const String immediateSyncTask = 'immediateSyncTask';

  /// Initialize sync manager
  /// Sets up connectivity listener and periodic sync
  Future<void> initialize() async {
    debugPrint('🔄 [SYNC MANAGER] Initializing...');
    
    // Initialize notification service
    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('⚠️ [SYNC MANAGER] Notification service init failed: $e');
    }
    
    // Register periodic sync task (runs every 15 minutes)
    await _registerPeriodicSync();
    
    // Listen to connectivity changes
    _setupConnectivityListener();
    
    debugPrint('✅ [SYNC MANAGER] Initialized');
  }

  /// Register periodic background sync task
  Future<void> _registerPeriodicSync() async {
    // workmanager is only implemented on Android/iOS. On Windows/macOS/Linux/Web,
    // we run periodic sync only while the app is open.
    final supportsWorkmanager =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (!supportsWorkmanager) {
      _foregroundPeriodicTimer?.cancel();
      // Small initial delay to avoid impacting startup.
      Timer(const Duration(minutes: 1), () {
        triggerSync(immediate: true);
      });
      _foregroundPeriodicTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => triggerSync(immediate: true),
      );
      debugPrint(
        'ℹ️ [SYNC MANAGER] Workmanager not supported on this platform; '
        'using foreground periodic sync only',
      );
      return;
    }

    try {
      await Workmanager().registerPeriodicTask(
        periodicSyncTask,
        periodicSyncTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        initialDelay: const Duration(minutes: 1),
      );
      debugPrint('✅ [SYNC MANAGER] Periodic sync task registered');
    } catch (e, stack) {
      debugPrint('❌ [SYNC MANAGER] Failed to register periodic task: $e');
      debugPrint('❌ [SYNC MANAGER] Stack: $stack');
      // Don't throw, just log the error
    }
  }

  /// Setup connectivity change listener
  void _setupConnectivityListener() {
    try {
      _connectivitySubscription?.cancel();
      
      _connectivitySubscription = ConnectivityHelper.instance.onConnectivityChange.listen(
        (isConnected) async {
          try {
            if (isConnected) {
              debugPrint('🌐 [SYNC MANAGER] Internet connection restored');
              // Wait a bit for connection to stabilize
              await Future.delayed(const Duration(seconds: 2));
              // Trigger immediate sync
              await triggerSync(immediate: true);
            } else {
              debugPrint('📴 [SYNC MANAGER] Internet connection lost');
            }
          } catch (e) {
            debugPrint('❌ [SYNC MANAGER] Error in connectivity listener: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ [SYNC MANAGER] Connectivity stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ [SYNC MANAGER] Failed to setup connectivity listener: $e');
      // Don't throw, just log the error
    }
  }

  /// Trigger sync manually or automatically
  /// [immediate] - If true, syncs immediately. If false, schedules via WorkManager
  Future<void> triggerSync({bool immediate = false}) async {
    if (_isSyncing) {
      debugPrint('⏳ [SYNC MANAGER] Sync already in progress');
      return;
    }

    if (immediate) {
      // Sync immediately in foreground
      await _performSync();
    } else {
      final supportsWorkmanager =
          !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      if (!supportsWorkmanager) {
        // No background scheduler on this platform; do it now.
        await _performSync();
        return;
      }

      // Schedule via WorkManager (background)
      try {
        await Workmanager().registerOneOffTask(
          immediateSyncTask,
          immediateSyncTask,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          initialDelay: const Duration(seconds: 5),
        );
        debugPrint('📅 [SYNC MANAGER] Sync task scheduled');
      } catch (e) {
        debugPrint('❌ [SYNC MANAGER] Failed to schedule sync: $e');
        // Fallback to immediate sync
        await _performSync();
      }
    }
  }

  /// Perform actual synchronization
  Future<void> _performSync() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      debugPrint('🔄 [SYNC MANAGER] Starting sync...');

      // Check internet connection
      final isOnline = await NetworkUtils.hasInternetConnection();
      if (!isOnline) {
        debugPrint('⚠️ [SYNC MANAGER] No internet connection, skipping sync');
        return;
      }

      // Get API client (use Get.find if available, otherwise use NetworkModule)
      ApiClient apiClient;
      try {
        apiClient = Get.find<ApiClient>();
      } catch (e) {
        // Fallback to NetworkModule if Get.find fails
        apiClient = NetworkModule.getApiClient();
      }
      final syncService = Synchronisation(apiClient: apiClient);

      // Sync pending orders with notification
      // Only show notification if app is in foreground or background (not killed)
      final showNotification = true; // You can make this conditional based on app state
      await syncService.syncPendingOrders(_db, showNotification: showNotification);

      debugPrint('✅ [SYNC MANAGER] Sync completed');
    } catch (e, stack) {
      debugPrint('❌ [SYNC MANAGER] Sync failed: $e');
      debugPrint(stack.toString());
      
      // Retry after 5 minutes if failed
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }
  }

  /// Schedule retry after failure
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 5), () {
      debugPrint('🔄 [SYNC MANAGER] Retrying sync after failure...');
      triggerSync(immediate: true);
    });
  }

  /// Get sync status
  bool get isSyncing => _isSyncing;

  /// Get pending orders count
  Future<int> getPendingOrdersCount() async {
    final orders = await _db.getPendingOrders();
    return orders.length;
  }

  /// Cancel all sync operations
  void cancelSync() {
    _retryTimer?.cancel();
    _foregroundPeriodicTimer?.cancel();
    _connectivitySubscription?.cancel();
    final supportsWorkmanager =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (supportsWorkmanager) {
      Workmanager().cancelByUniqueName(periodicSyncTask);
      Workmanager().cancelByUniqueName(immediateSyncTask);
    }
    debugPrint('🛑 [SYNC MANAGER] All sync operations cancelled');
  }

  /// Dispose resources
  void dispose() {
    cancelSync();
    _isSyncing = false;
  }
}

