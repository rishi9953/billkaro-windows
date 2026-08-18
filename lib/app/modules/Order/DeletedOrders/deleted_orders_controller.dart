import 'dart:async';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/sync/order_sync_util.dart';
import 'package:billkaro/config/config.dart';

class DeletedOrdersController extends BaseController {
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;

  var currentPage = 1.obs;
  var hasMoreOrders = true.obs;
  var isLoadingMore = false.obs;
  final int ordersPerPage = 20;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _lastConnectivityState = false;
  bool _hasLoadedFromApi = false;

  Future<void> getOrderList({
    bool forceApiRefresh = false,
    bool loadMore = false,
  }) async {
    try {
      if (loadMore) {
        isLoadingMore.value = true;
      }

      final db = AppDatabase();
      final isOnline = await NetworkUtils.hasInternetConnection();
      final outletId = appPref.selectedOutlet?.id;

      if (outletId == null) {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(description: loc.no_outlet_selected);
        return;
      }

      final userId = appPref.ordersApiUserId;
      if (userId == null || userId.isEmpty) {
        if (!loadMore) {
          showError(description: 'User or outlet information is missing.');
        }
        return;
      }

      List<OrderModel> apiOrders = [];
      List<OrderModel> localOrders = [];

      if (!loadMore) {
        localOrders = await db.getAllOrders(outletId: outletId);
      }

      if (isOnline && (!_hasLoadedFromApi || forceApiRefresh || loadMore)) {
        final response = await callApi(
          apiClient.getOrdersByStatus(
            userId,
            outletId,
            loadMore ? currentPage.value : 1,
            ordersPerPage,
            'deleted',
          ),
          showLoader: !loadMore,
        );

        if (response?.status == 'success') {
          apiOrders = response!.data;
          hasMoreOrders.value = response.data.length >= ordersPerPage;

          if (hasMoreOrders.value) {
            if (loadMore) {
              currentPage.value++;
            } else {
              currentPage.value = 2;
            }
          }

          if (!loadMore) {
            _hasLoadedFromApi = true;
          }

          await db.insertOrders(apiOrders, outletId, isSyncedFromApi: true);
        }
      } else if (!isOnline) {
        _hasLoadedFromApi = false;
        if (!loadMore) {
          localOrders = await db.getAllOrders(outletId: outletId);
        }
      }

      final Map<String, OrderModel> mergedOrders = {};

      if (!loadMore) {
        for (final order in localOrders) {
          mergedOrders[order.id] = order;
        }
      }

      final unsyncedIds = await db.getUnsyncedOrderIds(outletId: outletId);
      mergeRemoteOrders(mergedOrders, apiOrders, unsyncedIds: unsyncedIds);

      final deletedOrders = mergedOrders.values
          .where((e) => e.status == 'deleted')
          .toList();

      deletedOrders.sort((a, b) {
        final dateA = DateTime.parse(a.createdAt.toString());
        final dateB = DateTime.parse(b.createdAt.toString());
        return dateB.compareTo(dateA);
      });

      if (loadMore) {
        final newOrders = deletedOrders.where((order) {
          return !allOrders.any(
            (existingOrder) => existingOrder.id == order.id,
          );
        }).toList();
        allOrders.addAll(newOrders);
      } else {
        allOrders.value = deletedOrders;
        currentPage.value = 1;
      }
    } catch (e) {
      debugPrint('❌ Error fetching deleted orders: $e');
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_load_orders);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreOrders() async {
    if (!hasMoreOrders.value || isLoadingMore.value) return;
    await getOrderList(loadMore: true);
  }

  Future<bool> restoreOrder(OrderModel order) async {
    final orderId = order.id;
    if (orderId.isEmpty) {
      showError(description: 'Order id is missing.');
      return false;
    }

    try {
      final db = AppDatabase();
      final isOnline = await NetworkUtils.hasInternetConnection();
      var restoreStatus = 'pending';

      if (isOnline) {
        final response = await callApi(
          apiClient.restoreOrder(orderId),
          showLoader: true,
        );
        final status = response is Map ? response['status'] : null;
        if (status != null && status != 'success') {
          showError(description: 'Failed to restore order.');
          return false;
        }
        final data = response is Map ? response['data'] : null;
        if (data is Map && data['status'] is String) {
          restoreStatus = data['status'] as String;
        }
        await db.updateOrderStatus(orderId: orderId, status: restoreStatus);
      } else {
        await db.updateOrderStatus(
          orderId: orderId,
          status: restoreStatus,
          markPendingSync: true,
        );
      }
      allOrders.removeWhere((e) => e.id == orderId);

      final loc = AppLocalizations.of(Get.context!)!;
      showSuccess(description: loc.order_restored_successfully);
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring order: $e');
      showError(description: 'Failed to restore order.');
      return false;
    }
  }

  @override
  void onReady() {
    getOrderList();

    _connectivitySubscription = ConnectivityHelper.instance.onConnectivityChange
        .listen((isConnected) {
          if (isConnected && !_lastConnectivityState && !_hasLoadedFromApi) {
            getOrderList(forceApiRefresh: true);
          }
          _lastConnectivityState = isConnected;
        });

    _lastConnectivityState = ConnectivityHelper.instance.isConnected;
    super.onReady();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
