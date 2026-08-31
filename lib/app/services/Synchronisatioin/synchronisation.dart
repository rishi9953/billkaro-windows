import 'dart:async';

import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/billing/platform_fee_service.dart';
import 'package:billkaro/app/services/notification/sync_notification_service.dart';
import 'package:billkaro/app/services/sync/item_catalog_sync.dart';
import 'package:billkaro/app/services/sync/order_sync_util.dart';
import 'package:billkaro/app/services/sync/promotion_sync.dart';
import 'package:billkaro/app/services/sync/refresh_online_data.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Result of a full offline → online sync cycle (items, then orders, then pull).
class OrderSyncResult {
  final int syncedCount;
  final int failedCount;
  final int ordersPending;
  final int itemsSynced;
  final int itemsFailed;
  final int itemsPending;
  final Set<String> affectedOutletIds;
  final bool pulledFreshData;

  const OrderSyncResult({
    required this.syncedCount,
    required this.failedCount,
    this.ordersPending = 0,
    this.itemsSynced = 0,
    this.itemsFailed = 0,
    this.itemsPending = 0,
    required this.affectedOutletIds,
    this.pulledFreshData = false,
  });

  int get pendingRemaining => ordersPending + itemsPending;

  bool get hadSuccessfulSync => syncedCount > 0 || itemsSynced > 0;

  bool get isFullyComplete => pendingRemaining == 0 && failedCount == 0;
}

class Synchronisation {
  final ApiClient apiClient;
  final SyncNotificationService _notificationService = SyncNotificationService();

  Synchronisation({required this.apiClient});

  /// Push pending items, remap local item IDs on pending bills, push orders,
  /// then pull fresh outlet data. Called by [SyncManager] and Workmanager.
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
          affectedOutletIds: {},
        );
      }

      if (fromReconnect) {
        await _requeueFailedWork(db);
      }

      final catalog = ItemCatalogSync(apiClient: apiClient, db: db);
      final itemResult = await catalog.pushPendingItems();
      if (itemResult.synced > 0) {
        debugPrint('✅ [SYNC] Synced ${itemResult.synced} pending item(s)');
      }

      // Fetch orders after item push so remapped server item IDs are used.
      final pendingOrders = await db.getPendingOrders();
      debugPrint(
        '📦 [SYNC] ${pendingOrders.length} pending order(s), '
        '${itemResult.pending} pending item(s)',
      );

      final workTotal = pendingOrders.length + itemResult.synced + itemResult.failed;
      if (showNotification) {
        if (workTotal == 0) {
          await _notificationService.cancelSyncNotification();
        } else {
          await _notificationService.showSyncStarted(totalOrders: workTotal);
        }
      }

      final orderPush = await _pushPendingOrders(
        db,
        pendingOrders,
        showNotification: showNotification,
        alreadySynced: itemResult.synced,
      );

      final ordersPending = await db.countPendingOrders();
      final itemsPending = await db.countPendingItems();
      final affectedOutlets = {...orderPush.affectedOutletIds};
      final selectedOutletId = appPref.selectedOutlet?.id;
      if (selectedOutletId != null) affectedOutlets.add(selectedOutletId);

      var pulledFreshData = false;
      final shouldPull = fromReconnect ||
          orderPush.synced > 0 ||
          itemResult.synced > 0;
      if (shouldPull) {
        pulledFreshData = await _pullAndRefreshOutlets(
          db,
          userId,
          appPref,
          outletIds: affectedOutlets,
        );
      }

      if (selectedOutletId != null) {
        unawaited(catalog.pullCatalogInBackground(selectedOutletId));
      }

      _notifyUser(
        ordersSynced: orderPush.synced,
        ordersFailed: orderPush.failed,
        itemsSynced: itemResult.synced,
        itemsFailed: itemResult.failed,
      );

      if (showNotification && workTotal > 0) {
        await _notificationService.showSyncCompleted(
          syncedCount: orderPush.synced + itemResult.synced,
          totalCount: workTotal,
          hasErrors: orderPush.failed > 0 || itemResult.failed > 0,
        );
      }

      if (refreshUi && (shouldPull || itemResult.synced > 0)) {
        await refreshControllersAfterOnlineSync();
      }

      debugPrint(
        '📊 [SYNC] Done: orders ${orderPush.synced} synced / ${orderPush.failed} failed / '
        '$ordersPending pending; items ${itemResult.synced} synced / '
        '${itemResult.failed} failed / $itemsPending pending',
      );

      return OrderSyncResult(
        syncedCount: orderPush.synced,
        failedCount: orderPush.failed,
        ordersPending: ordersPending,
        itemsSynced: itemResult.synced,
        itemsFailed: itemResult.failed,
        itemsPending: itemsPending,
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
        affectedOutletIds: {},
      );
    }
  }

  Future<void> _requeueFailedWork(AppDatabase db) async {
    final resetOrders = await db.resetFailedOrdersToPending();
    if (resetOrders > 0) {
      debugPrint('🔁 [SYNC] Re-queued $resetOrders previously failed order(s)');
    }
    final resetItems = await db.resetFailedItemsToPending();
    if (resetItems > 0) {
      debugPrint('🔁 [SYNC] Re-queued $resetItems previously failed item(s)');
    }
  }

  Future<_OrderPushResult> _pushPendingOrders(
    AppDatabase db,
    List<OrderModel> pendingOrders, {
    required bool showNotification,
    required int alreadySynced,
  }) async {
    if (pendingOrders.isEmpty) {
      return const _OrderPushResult();
    }

    var successCount = 0;
    var failCount = 0;
    final affectedOutlets = <String>{};
    var currentIndex = 0;

    for (final order in pendingOrders) {
      currentIndex++;
      final localId = order.id;

      if (showNotification) {
        await _notificationService.showSyncProgress(
          current: alreadySynced + currentIndex,
          total: alreadySynced + pendingOrders.length,
          synced: alreadySynced + successCount,
        );
      }

      try {
        await _uploadPendingOrder(db, order);
        affectedOutlets.add(order.outletId);
        successCount++;
        debugPrint('✅ [SYNC] Order $localId uploaded');
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
    }

    return _OrderPushResult(
      synced: successCount,
      failed: failCount,
      affectedOutletIds: affectedOutlets,
    );
  }

  Future<void> _uploadPendingOrder(AppDatabase db, OrderModel order) async {
    final localId = order.id;
    final status = order.status.toLowerCase();
    debugPrint('📤 [SYNC] Uploading order $localId (status=$status)');

    if (status == 'deleted') {
      if (shouldCreateOnServer(localId)) {
        await db.deleteOrderCompletely(localId);
        return;
      }
      final response = await apiClient.softDeleteOrder(localId);
      if (response is Map && response['status']?.toString() != 'success') {
        throw FormatException('softDelete failed for $localId: $response');
      }
      await db.markOrderAsSynced(localId);
      return;
    }

    final payload = buildOrderSyncPayload(order);
    if (shouldCreateOnServer(localId) && Get.isRegistered<AppPref>()) {
      final appPref = Get.find<AppPref>();
      if (PlatformFeeService.consumePendingFeeForOrder(appPref, localId)) {
        payload['chargePlatformFee'] = true;
      }
    }

    final response = shouldCreateOnServer(localId)
        ? await apiClient.addOrder(payload)
        : await apiClient.updateOrder(localId, payload);

    final serverOrder = parseSyncedOrderFromResponse(response, order);
    if (serverOrder == null) {
      if (response is Map && response['status']?.toString() == 'success') {
        await db.markOrderAsSynced(localId);
        return;
      }
      throw FormatException('Invalid sync response for $localId: $response');
    }

    if (localId != serverOrder.id) {
      await db.reconcileSyncedOrder(
        localOrderId: localId,
        serverOrder: serverOrder,
      );
    } else {
      await db.insertOrders(
        [serverOrder],
        serverOrder.outletId,
        isSyncedFromApi: true,
        protectUnsynced: false,
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

        await PromotionSync(apiClient: apiClient, db: db).load(
          outletId: outletId,
          activeOnly: false,
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

      final catalog = ItemCatalogSync(apiClient: apiClient, db: db);
      await catalog.pushPendingItems();

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

      await _uploadPendingOrder(db, order);

      await refreshControllersAfterOnlineSync();
      return true;
    } catch (e) {
      debugPrint('❌ [SYNC] Failed to sync order $orderId: $e');
      return false;
    }
  }

  void _notifyUser({
    required int ordersSynced,
    required int ordersFailed,
    required int itemsSynced,
    required int itemsFailed,
  }) {
    if (!Get.isRegistered<AppPref>()) return;

    final failed = ordersFailed + itemsFailed;
    final synced = ordersSynced + itemsSynced;
    if (failed > 0) {
      showError(
        description:
            '$failed record(s) could not sync. They will retry when you are back online.',
      );
      return;
    }
    if (synced == 0) return;

    showSuccess(description: _successMessage(ordersSynced, itemsSynced));
  }

  String _successMessage(int orders, int items) {
    if (orders > 0 && items > 0) {
      return '$orders order(s) and $items item(s) synced successfully';
    }
    if (items > 0) {
      return items == 1
          ? '1 offline item synced successfully'
          : '$items offline items synced successfully';
    }
    return orders == 1
        ? '1 offline order synced successfully'
        : '$orders offline orders synced successfully';
  }
}

class _OrderPushResult {
  const _OrderPushResult({
    this.synced = 0,
    this.failed = 0,
    this.affectedOutletIds = const <String>{},
  });

  final int synced;
  final int failed;
  final Set<String> affectedOutletIds;
}
