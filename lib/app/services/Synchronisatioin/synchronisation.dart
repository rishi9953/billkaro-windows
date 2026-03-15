import 'package:billkaro/config/config.dart';
import 'package:billkaro/app/services/notification/sync_notification_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class Synchronisation {
  final ApiClient apiClient;
  final SyncNotificationService _notificationService = SyncNotificationService();

  Synchronisation({required this.apiClient});

  /// Sync all pending orders to the server
  /// Returns true if sync was successful, false otherwise
  Future<bool> syncPendingOrders(AppDatabase db, {bool showNotification = true}) async {
    debugPrint('🔄 [SYNC] Starting sync process...');

    try {
      // Initialize notification service
      if (showNotification) {
        await _notificationService.initialize();
      }

      // Check internet
      final isOnline = await NetworkUtils.hasInternetConnection();
      if (!isOnline) {
        debugPrint('⚠️ [SYNC] No internet connection');
        if (showNotification) {
          await _notificationService.showSyncFailed(
            errorMessage: 'No internet connection',
          );
        }
        return false;
      }

      // Get selected outlet ID
      final appPref = Get.find<AppPref>();
      final selectedOutletId = appPref.selectedOutlet?.id;
      if (selectedOutletId == null) {
        debugPrint('⚠️ [SYNC] No outlet selected, skipping sync');
        if (showNotification) {
          await _notificationService.showSyncFailed(
            errorMessage: 'No outlet selected',
          );
        }
        return false;
      }

      // Get pending orders for the selected outlet only
      final allPendingOrders = await db.getPendingOrders();
      final orders = allPendingOrders.where((order) => order.outletId == selectedOutletId).toList();
      debugPrint('📦 [SYNC] Found ${orders.length} pending orders for outlet $selectedOutletId (out of ${allPendingOrders.length} total)');

      if (orders.isEmpty) {
        debugPrint('✅ [SYNC] No orders to sync for selected outlet');
        if (showNotification) {
          await _notificationService.cancelSyncNotification();
        }
        return true;
      }

      // Show sync started notification
      if (showNotification) {
        await _notificationService.showSyncStarted(totalOrders: orders.length);
      }

      int successCount = 0;
      int failCount = 0;
      final List<String> failedOrderIds = [];
      int currentIndex = 0;

      for (final order in orders) {
        currentIndex++;
        try {
          debugPrint('📤 [SYNC] Syncing order: ${order.id} ($currentIndex/${orders.length})');

          // Update progress notification
          if (showNotification) {
            await _notificationService.showSyncProgress(
              current: currentIndex,
              total: orders.length,
              synced: successCount,
            );
          }

          // Call API to sync order
          await apiClient.addOrder(order.toJson());
          
          // Mark as synced after successful API call
          await db.markOrderAsSynced(order.id);
          successCount++;
          debugPrint('✅ [SYNC] Order ${order.id} synced successfully');

          // Update progress after successful sync
          if (showNotification) {
            await _notificationService.showSyncProgress(
              current: currentIndex,
              total: orders.length,
              synced: successCount,
            );
          }
        } on DioException catch (e) {
          failCount++;
          failedOrderIds.add(order.id);
          debugPrint('❌ [SYNC] Failed order ${order.id}: ${e.message}');
          
          // Don't retry on client errors (4xx), but retry on server errors (5xx)
          final statusCode = e.response?.statusCode;
          if (statusCode != null && statusCode >= 400 && statusCode < 500) {
            debugPrint('⚠️ [SYNC] Client error for order ${order.id}, will not retry');
          }

          // Update progress even on failure
          if (showNotification) {
            await _notificationService.showSyncProgress(
              current: currentIndex,
              total: orders.length,
              synced: successCount,
            );
          }
        } catch (e, stack) {
          failCount++;
          failedOrderIds.add(order.id);
          debugPrint('❌ [SYNC] Failed order ${order.id}: $e');
          debugPrint(stack.toString());

          // Update progress even on failure
          if (showNotification) {
            await _notificationService.showSyncProgress(
              current: currentIndex,
              total: orders.length,
              synced: successCount,
            );
          }
        }
      }

      debugPrint('📊 [SYNC] Summary: $successCount OK, $failCount failed');
      
      if (failedOrderIds.isNotEmpty) {
        debugPrint('❌ [SYNC] Failed order IDs: ${failedOrderIds.join(", ")}');
      }

      // Show completion notification
      if (showNotification) {
        await _notificationService.showSyncCompleted(
          syncedCount: successCount,
          totalCount: orders.length,
          hasErrors: failCount > 0,
        );
      }

      // Return true if at least some orders were synced
      return successCount > 0;
    } catch (e, stack) {
      debugPrint('🔴 [SYNC] Critical error: $e');
      debugPrint(stack.toString());
      
      if (showNotification) {
        await _notificationService.showSyncFailed(
          errorMessage: 'Sync failed: ${e.toString()}',
        );
      }
      
      return false;
    }
  }

  /// Sync a single order (useful for retry logic)
  Future<bool> syncSingleOrder(AppDatabase db, String orderId) async {
    try {
      final isOnline = await NetworkUtils.hasInternetConnection();
      if (!isOnline) {
        debugPrint('⚠️ [SYNC] No internet connection for order $orderId');
        return false;
      }

      // Get selected outlet ID
      final appPref = Get.find<AppPref>();
      final selectedOutletId = appPref.selectedOutlet?.id;
      if (selectedOutletId == null) {
        debugPrint('⚠️ [SYNC] No outlet selected, cannot sync order $orderId');
        return false;
      }

      final orders = await db.getPendingOrders();
      final order = orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      // Check if order belongs to selected outlet
      if (order.outletId != selectedOutletId) {
        debugPrint('⚠️ [SYNC] Order $orderId belongs to outlet ${order.outletId}, but selected outlet is $selectedOutletId. Skipping sync.');
        return false;
      }

      debugPrint('📤 [SYNC] Syncing single order: $orderId');

      final response = await apiClient.addOrder(order.toJson());
      
      if (response != null) {
        await db.markOrderAsSynced(orderId);
        debugPrint('✅ [SYNC] Order $orderId synced successfully');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SYNC] Failed to sync order $orderId: $e');
      return false;
    }
  }
}
