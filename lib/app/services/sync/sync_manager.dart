import 'dart:async';
import 'dart:io' show Platform;
import 'package:billkaro/app/services/Synchronisatioin/synchronisation.dart';
import 'package:billkaro/app/services/Network/network_module.dart';
import 'package:billkaro/app/services/notification/sync_notification_service.dart';
import 'package:billkaro/app/services/sync/refresh_online_data.dart';
import 'package:billkaro/config/config.dart';
import 'package:workmanager/workmanager.dart';

/// Coordinates offline → online sync: push pending orders, pull fresh data,
/// and refresh all registered UI controllers.
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final AppDatabase _db = AppDatabase();
  final SyncNotificationService _notificationService =
      SyncNotificationService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _pendingSyncQueued = false;
  bool _wasOffline = false;
  Timer? _retryTimer;
  Timer? _reconnectDebounceTimer;
  Timer? _foregroundPeriodicTimer;

  static const String periodicSyncTask = 'periodicSyncTask';
  static const String connectivitySyncTask = 'connectivitySyncTask';
  static const String immediateSyncTask = 'immediateSyncTask';

  static const Duration _reconnectDebounce = Duration(seconds: 2);
  static const Duration _stabilityRecheck = Duration(milliseconds: 800);
  bool get _autoSyncEnabled {
    if (!Get.isRegistered<AppPref>()) return true;
    return Get.find<AppPref>().autoSyncEnabled;
  }

  Future<void> initialize() async {
    debugPrint('🔄 [SYNC MANAGER] Initializing...');

    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('⚠️ [SYNC MANAGER] Notification service init failed: $e');
    }

    _wasOffline = !ConnectivityHelper.instance.isConnected;
    if (_autoSyncEnabled) {
      await _registerPeriodicSync();
      _setupConnectivityListener();
    } else {
      debugPrint('ℹ️ [SYNC MANAGER] Auto sync disabled by settings');
    }

    // Sync any leftover pending orders on cold start when already online.
    if (_autoSyncEnabled && !_wasOffline) {
      unawaited(triggerSync(immediate: true, fromReconnect: false));
    }

    debugPrint('✅ [SYNC MANAGER] Initialized');
  }

  Future<void> _registerPeriodicSync() async {
    final supportsWorkmanager =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (!supportsWorkmanager) {
      _foregroundPeriodicTimer?.cancel();
      Timer(const Duration(minutes: 1), () {
        triggerSync(immediate: true, fromReconnect: false);
      });
      _foregroundPeriodicTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => triggerSync(immediate: true, fromReconnect: false),
      );
      debugPrint(
        'ℹ️ [SYNC MANAGER] Foreground periodic sync enabled (15 min)',
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
    }
  }

  void _setupConnectivityListener() {
    try {
      _connectivitySubscription?.cancel();

      _connectivitySubscription =
          ConnectivityHelper.instance.onConnectivityChange.listen(
        (isConnected) {
          if (!isConnected) {
            _wasOffline = true;
            _reconnectDebounceTimer?.cancel();
            debugPrint('📴 [SYNC MANAGER] Internet connection lost');
            return;
          }

          debugPrint('🌐 [SYNC MANAGER] Connectivity restored — scheduling sync');
          _reconnectDebounceTimer?.cancel();
          _reconnectDebounceTimer = Timer(_reconnectDebounce, () async {
            final fromReconnect = _wasOffline;
            _wasOffline = false;
            await triggerSync(immediate: true, fromReconnect: fromReconnect);
          });
        },
        onError: (error) {
          debugPrint('❌ [SYNC MANAGER] Connectivity stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ [SYNC MANAGER] Failed to setup connectivity listener: $e');
    }
  }

  /// Trigger sync manually or automatically.
  Future<void> triggerSync({
    bool immediate = false,
    bool fromReconnect = false,
    bool force = false,
  }) async {
    if (!_autoSyncEnabled && !force) {
      debugPrint('⏸️ [SYNC MANAGER] Auto sync is disabled');
      return;
    }

    if (_isSyncing) {
      _pendingSyncQueued = true;
      debugPrint('⏳ [SYNC MANAGER] Sync in progress — queued follow-up');
      return;
    }

    if (immediate) {
      await _performSync(fromReconnect: fromReconnect);
      return;
    }

    final supportsWorkmanager =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!supportsWorkmanager) {
      await _performSync(fromReconnect: fromReconnect);
      return;
    }

    try {
      await Workmanager().registerOneOffTask(
        immediateSyncTask,
        immediateSyncTask,
        constraints: Constraints(networkType: NetworkType.connected),
        initialDelay: const Duration(seconds: 5),
      );
      debugPrint('📅 [SYNC MANAGER] Sync task scheduled');
    } catch (e) {
      debugPrint('❌ [SYNC MANAGER] Failed to schedule sync: $e');
      await _performSync(fromReconnect: fromReconnect);
    }
  }

  Future<void> _performSync({required bool fromReconnect}) async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      debugPrint(
        '🔄 [SYNC MANAGER] Starting sync (reconnect=$fromReconnect)...',
      );

      if (!await _verifyStableConnection()) {
        debugPrint('⚠️ [SYNC MANAGER] Connection not stable — aborting sync');
        return;
      }

      final ApiClient apiClient = _resolveApiClient();
      final syncService = Synchronisation(apiClient: apiClient);

      final result = await syncService.syncPendingOrders(
        _db,
        showNotification: true,
        fromReconnect: fromReconnect,
        refreshUi: true,
      );

      if (result.pendingRemaining > 0) {
        _scheduleRetry();
      } else {
        _retryTimer?.cancel();
      }

      debugPrint(
        '✅ [SYNC MANAGER] Sync finished — orders=${result.syncedCount}, '
        'items=${result.itemsSynced}, pending=${result.pendingRemaining}',
      );
    } catch (e, stack) {
      debugPrint('❌ [SYNC MANAGER] Sync failed: $e');
      debugPrint(stack.toString());
      _scheduleRetry();
    } finally {
      _isSyncing = false;

      if (_pendingSyncQueued) {
        _pendingSyncQueued = false;
        debugPrint('🔁 [SYNC MANAGER] Running queued follow-up sync');
        await triggerSync(immediate: true, fromReconnect: fromReconnect);
      }
    }
  }

  Future<bool> _verifyStableConnection() async {
    if (!await NetworkUtils.hasInternetConnection()) {
      return false;
    }
    await Future.delayed(_stabilityRecheck);
    return NetworkUtils.hasInternetConnection();
  }

  ApiClient _resolveApiClient() {
    try {
      return Get.find<ApiClient>();
    } catch (_) {
      return NetworkModule.getApiClient();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 2), () {
      debugPrint('🔄 [SYNC MANAGER] Retrying sync after partial failure...');
      triggerSync(immediate: true, fromReconnect: false);
    });
  }

  bool get isSyncing => _isSyncing;

  Future<int> getPendingOrdersCount() async {
    return _db.countPendingOrders();
  }

  Future<int> getPendingItemsCount() async {
    return _db.countPendingItems();
  }

  /// Force a full online restore: sync + refresh (callable from UI).
  Future<void> forceOnlineRestore() async {
    await triggerSync(immediate: true, fromReconnect: true, force: true);
    if (!await NetworkUtils.hasInternetConnection()) return;
    await refreshControllersAfterOnlineSync();
  }

  Future<void> enableAutoSync() async {
    if (!_autoSyncEnabled) return;
    await _registerPeriodicSync();
    _setupConnectivityListener();
    debugPrint('✅ [SYNC MANAGER] Auto sync enabled');
  }

  void disableAutoSync() {
    cancelSync();
    debugPrint('⏸️ [SYNC MANAGER] Auto sync disabled');
  }

  void cancelSync() {
    _retryTimer?.cancel();
    _reconnectDebounceTimer?.cancel();
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

  void dispose() {
    cancelSync();
    _isSyncing = false;
    _pendingSyncQueued = false;
  }
}
