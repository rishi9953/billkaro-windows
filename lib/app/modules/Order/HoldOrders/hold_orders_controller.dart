import 'dart:async';
import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';

class HoldOrdersController extends BaseController {
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;
  final RxString selectedFilter = 'all'.obs;

  // Pagination
  var currentPage = 1.obs;
  var hasMoreOrders = true.obs;
  var isLoadingMore = false.obs;
  final int ordersPerPage = 20;

  // Connectivity listener
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
        showError(description: 'No outlet selected');
        return;
      }

      List<OrderModel> apiOrders = [];
      List<OrderModel> localOrders = [];

      /// 🔹 Always load local orders (only on initial load)
      if (!loadMore) {
        localOrders = await db.getAllOrders(outletId: outletId);
      }

      /// 🔹 Fetch API orders if online (only if not already loaded or forced or loading more)
      if (isOnline && (!_hasLoadedFromApi || forceApiRefresh || loadMore)) {
        debugPrint(
          '🌐 Internet available → fetching from API - Page: ${currentPage.value}',
        );

        final response = await callApi(
          apiClient.getOrders(
            appPref.user!.id!,
            outletId,
            loadMore ? currentPage.value : 1, // page
            ordersPerPage, // limit
            null, // category
            null, // paymentReceivedIn
            null, // startDate
            null, // endDate
          ),
          showLoader: !loadMore,
        );

        if (response?.status == 'success') {
          apiOrders = response!.data;

          // Check pagination

          hasMoreOrders.value = response.data.length >= ordersPerPage;

          // Update page number for next load
          if (hasMoreOrders.value) {
            if (loadMore) {
              currentPage.value++; // Increment for next page
            } else {
              currentPage.value = 2; // Next page will be 2 after initial load
            }
          }

          if (!loadMore) {
            _hasLoadedFromApi = true;
          }
        }
      } else if (!isOnline) {
        debugPrint('📴 No internet → loading from SQLite only');
        _hasLoadedFromApi = false;
        if (!loadMore) {
          localOrders = await db.getAllOrders(outletId: outletId);
        }
      } else {
        debugPrint('📴 Using cached data - API already loaded');
      }

      /// 🔹 Merge Local + API (avoid duplicates)
      final Map<String, OrderModel> mergedOrders = {};

      if (!loadMore) {
        for (final order in localOrders) {
          mergedOrders[order.id!] = order;
        }
      }

      for (final order in apiOrders) {
        mergedOrders[order.id!] = order;
      }

      /// 🔹 Pending orders only
      final pendingOrders = mergedOrders.values
          .where((e) => e.status == 'pending')
          .toList();

      /// 🔥 Sort latest first
      pendingOrders.sort((a, b) {
        final dateA = DateTime.parse(a.createdAt.toString());
        final dateB = DateTime.parse(b.createdAt.toString());
        return dateB.compareTo(dateA);
      });

      if (loadMore) {
        // Append new orders
        final newOrders = pendingOrders.where((order) {
          return !allOrders.any(
            (existingOrder) => existingOrder.id == order.id,
          );
        }).toList();
        allOrders.addAll(newOrders);
      } else {
        allOrders.value = pendingOrders;
        currentPage.value = 1;
      }

      debugPrint(
        '✅ Loaded ${allOrders.length} pending orders (API + Local merged)',
      );
    } catch (e) {
      debugPrint('❌ Error fetching pending orders: $e');
      showError(description: 'Failed to load orders');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load more orders
  Future<void> loadMoreOrders() async {
    if (!hasMoreOrders.value || isLoadingMore.value) return;
    await getOrderList(loadMore: true);
  }

  @override
  void onReady() {
    getOrderList();

    // Listen to connectivity changes
    _connectivitySubscription = ConnectivityHelper.instance.onConnectivityChange
        .listen((isConnected) {
          if (isConnected && !_lastConnectivityState && !_hasLoadedFromApi) {
            debugPrint(
              '🌐 Internet came back - refreshing hold orders from API',
            );
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
