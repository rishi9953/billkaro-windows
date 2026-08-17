import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/notification/sync_notification_service.dart';
import 'package:billkaro/app/services/sync/order_sync_util.dart';
import 'package:billkaro/app/services/sync/refresh_online_data.dart';
import 'package:billkaro/app/services/billing/platform_fee_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Result of a full offline → online sync cycle.
class OrderSyncResult {
  final int syncedCount;
  final int failedCount;
  final int pendingRemaining;
  final Set<String> affectedOutletIds;
  final bool pulledFreshData;

  const OrderSyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.pendingRemaining,
    required this.affectedOutletIds,
    this.pulledFreshData = false,
  });

  bool get hadSuccessfulSync => syncedCount > 0;
  bool get isFullyComplete => pendingRemaining == 0 && failedCount == 0;
}

class Synchronisation {
  final ApiClient apiClient;
  final SyncNotificationService _notificationService = SyncNotificationService();

  Synchronisation({required this.apiClient});

  /// Push pending orders, reconcile server IDs, then pull fresh outlet data.
  Future<OrderSyncResult> syncPendingOrders(
    AppDatabase db, {
    bool showNotification = true,
    bool fromReconnect = false,
    bool refreshUi = true,
  }) async {
    debugPrint('🔄 [SYNC] Starting sync (reconnect=$fromReconnect)...');

    try {
      if (showNotification) {
        await _notificationService.initialize();
      }

      if (!await NetworkUtils.hasInternetConnection()) {
        debugPrint('⚠️ [SYNC] No internet connection');
        if (showNotification) {
          await _notificationService.showSyncFailed(
            errorMessage: 'No internet connection',
          );
        }
        return const OrderSyncResult(
          syncedCount: 0,
          failedCount: 0,
          pendingRemaining: 0,
          affectedOutletIds: {},
        );
      }

      final appPref = Get.find<AppPref>();
      final userId = appPref.ordersApiUserId;
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ [SYNC] No logged-in user');
        return const OrderSyncResult(
          syncedCount: 0,
          failedCount: 0,
          pendingRemaining: 0,
          affectedOutletIds: {},
        );
      }

      if (fromReconnect) {
        final reset = await db.resetFailedOrdersToPending();
        if (reset > 0) {
          debugPrint('🔁 [SYNC] Re-queued $reset previously failed order(s)');
        }
      }

      final pendingOrders = await db.getPendingOrders();
      debugPrint('📦 [SYNC] ${pendingOrders.length} pending order(s)');

      if (pendingOrders.isEmpty) {
        if (showNotification) {
          await _notificationService.cancelSyncNotification();
        }
        var pulledFreshData = false;
        if (fromReconnect) {
          pulledFreshData = await _pullAndRefreshOutlets(
            db,
            userId,
            appPref,
          );
          if (refreshUi) {
            await refreshControllersAfterOnlineSync();
          }
        }
        return OrderSyncResult(
          syncedCount: 0,
          failedCount: 0,
          pendingRemaining: 0,
          affectedOutletIds: {},
          pulledFreshData: pulledFreshData,
        );
      }

      if (showNotification) {
        await _notificationService.showSyncStarted(
          totalOrders: pendingOrders.length,
        );
      }

      int successCount = 0;
      int failCount = 0;
      final affectedOutlets = <String>{};
      var currentIndex = 0;

      for (final order in pendingOrders) {
        currentIndex++;
        final localId = order.id;

        if (showNotification) {
          await _notificationService.showSyncProgress(
            current: currentIndex,
            total: pendingOrders.length,
            synced: successCount,
          );
        }

        try {
          final payload = buildOrderSyncPayload(order);
          if (PlatformFeeService.consumePendingFeeForOrder(appPref, localId)) {
            payload['chargePlatformFee'] = true;
          }
          debugPrint('📤 [SYNC] Uploading order $localId');

          final response = await apiClient.addOrder(payload);
          final serverOrder = parseSyncedOrderFromResponse(response, order);

          if (serverOrder == null) {
            throw FormatException(
              'Invalid addOrder response for $localId: $response',
            );
          }

          if (localId != serverOrder.id) {
            await db.reconcileSyncedOrder(
              localOrderId: localId,
              serverOrder: serverOrder,
            );
          } else {
            await db.markOrderAsSynced(localId);
          }

          affectedOutlets.add(serverOrder.outletId);
          successCount++;
          debugPrint('✅ [SYNC] Order $localId → ${serverOrder.id}');
        } on DioException catch (e) {
          failCount++;
          final statusCode = e.response?.statusCode;
          debugPrint(
            '❌ [SYNC] Dio error for $localId (${statusCode ?? 'no status'}): ${e.message}',
          );

          if (statusCode != null && statusCode >= 400 && statusCode < 500) {
            await db.markOrderSyncFailed(localId);
          }
        } catch (e, stack) {
          failCount++;
          debugPrint('❌ [SYNC] Failed order $localId: $e');
          debugPrint(stack.toString());
        }

        if (showNotification) {
          await _notificationService.showSyncProgress(
            current: currentIndex,
            total: pendingOrders.length,
            synced: successCount,
          );
        }
      }

      final pendingRemaining = await db.countPendingOrders();
      var pulledFreshData = false;

      if (successCount > 0 || fromReconnect) {
        pulledFreshData = await _pullAndRefreshOutlets(
          db,
          userId,
          appPref,
          outletIds: affectedOutlets,
        );
      }

      if (failCount > 0 && Get.isRegistered<AppPref>()) {
        showError(
          description:
              '$failCount order(s) could not sync. They will retry when you are back online.',
        );
      } else if (successCount > 0 && Get.isRegistered<AppPref>()) {
        showSuccess(
          description: successCount == 1
              ? '1 offline order synced successfully'
              : '$successCount offline orders synced successfully',
        );
      }

      if (showNotification) {
        await _notificationService.showSyncCompleted(
          syncedCount: successCount,
          totalCount: pendingOrders.length,
          hasErrors: failCount > 0,
        );
      }

      if (refreshUi && (successCount > 0 || fromReconnect)) {
        await refreshControllersAfterOnlineSync();
      }

      debugPrint(
        '📊 [SYNC] Done: $successCount synced, $failCount failed, '
        '$pendingRemaining still pending',
      );

      return OrderSyncResult(
        syncedCount: successCount,
        failedCount: failCount,
        pendingRemaining: pendingRemaining,
        affectedOutletIds: affectedOutlets,
        pulledFreshData: pulledFreshData,
      );
    } catch (e, stack) {
      debugPrint('🔴 [SYNC] Critical error: $e');
      debugPrint(stack.toString());

      if (showNotification) {
        await _notificationService.showSyncFailed(
          errorMessage: 'Sync failed: ${e.toString()}',
        );
      }

      return const OrderSyncResult(
        syncedCount: 0,
        failedCount: 0,
        pendingRemaining: 0,
        affectedOutletIds: {},
      );
    }
  }

  Future<bool> _pullAndRefreshOutlets(
    AppDatabase db,
    String userId,
    AppPref appPref, {
    Set<String>? outletIds,
  }) async {
    final targets = <String>{};

    if (outletIds != null && outletIds.isNotEmpty) {
      targets.addAll(outletIds);
    }
    final selected = appPref.selectedOutlet?.id;
    if (selected != null) targets.add(selected);

    if (targets.isEmpty) return false;

    var pulled = false;

    for (final outletId in targets) {
      try {
        if (!await NetworkUtils.hasInternetConnection()) break;

        debugPrint('📥 [SYNC] Pulling orders for outlet $outletId');
        final response = await apiClient.getOrders(
          userId,
          outletId,
          null,
          null,
          null,
          null,
          null,
          null,
        );

        if (response.status == 'success' && response.data.isNotEmpty) {
          await db.insertOrders(
            response.data,
            outletId,
            isSyncedFromApi: true,
          );
          pulled = true;
          debugPrint(
            '✅ [SYNC] Cached ${response.data.length} orders for $outletId',
          );
        }

        await OfflineCategoryLoader.load(
          outletId: outletId,
          fetchFromApi: () async {
            try {
              return await apiClient.getCategories(outletId);
            } catch (_) {
              return null;
            }
          },
        );
      } catch (e) {
        debugPrint('⚠️ [SYNC] Pull failed for outlet $outletId: $e');
      }
    }

    return pulled;
  }

  /// Sync a single order (manual retry).
  Future<bool> syncSingleOrder(AppDatabase db, String orderId) async {
    try {
      if (!await NetworkUtils.hasInternetConnection()) {
        return false;
      }

      final orders = await db.getPendingOrders();
      OrderModel? order;
      for (final candidate in orders) {
        if (candidate.id == orderId) {
          order = candidate;
          break;
        }
      }
      if (order == null) {
        debugPrint('⚠️ [SYNC] Order $orderId not in pending queue');
        return false;
      }

      final payload = buildOrderSyncPayload(order);
      final appPref = Get.find<AppPref>();
      if (PlatformFeeService.consumePendingFeeForOrder(appPref, order.id)) {
        payload['chargePlatformFee'] = true;
      }
      final response = await apiClient.addOrder(payload);
      final serverOrder = parseSyncedOrderFromResponse(response, order);
      if (serverOrder == null) return false;

      if (order.id != serverOrder.id) {
        await db.reconcileSyncedOrder(
          localOrderId: order.id,
          serverOrder: serverOrder,
        );
      } else {
        await db.markOrderAsSynced(orderId);
      }

      await refreshControllersAfterOnlineSync();
      return true;
    } catch (e) {
      debugPrint('❌ [SYNC] Failed to sync order $orderId: $e');
      return false;
    }
  }
}
