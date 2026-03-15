import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';

class ClosedOrdersController extends BaseController {
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;
  final RxString selectedFilter = 'all'.obs;

  // Pagination variables
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isLoadingMore = false.obs;
  final int itemsPerPage = 10;

  /// 🔹 Safe date parser (API + SQLite)
  DateTime _parseOrderDate(dynamic createdAt) {
    if (createdAt is DateTime) return createdAt;
    return DateTime.parse(createdAt.toString());
  }

  /// 🔹 Fetch orders (API → SQLite fallback) with pagination
  Future<void> getOrderList({bool loadMore = false}) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: 'No outlet selected');
      return;
    }

    // Prevent multiple simultaneous load more requests
    if (loadMore && isLoadingMore.value) {
      debugPrint('⏳ Already loading more, skipping...');
      return;
    }

    // If no more data available, don't make the request
    if (loadMore && !hasMoreData.value) {
      debugPrint('🛑 No more data to load');
      return;
    }

    if (loadMore) {
      isLoadingMore.value = true;
    }

    try {
      final isOnline = await NetworkUtils.hasInternetConnection();
      final db = AppDatabase();

      List<OrderModel> apiOrders = [];
      List<OrderModel> localOrders = [];

      /// 🔹 Load local orders only on initial load (not when loading more)
      if (!loadMore) {
        localOrders = await db.getAllOrders(outletId: outletId);
        currentPage.value = 1; // Reset pagination
        hasMoreData.value = true; // Reset hasMore flag
      }

      /// 🔹 Fetch API orders if online (paginated)
      if (isOnline) {
        // When loading more, request the NEXT page; on initial load request page 1
        final int pageToFetch = loadMore ? currentPage.value + 1 : 1;
        debugPrint(
          '🌐 Internet available → fetching API orders (Page $pageToFetch, limit $itemsPerPage)',
        );

        final response = await callApi(
          apiClient.getOrders(
            appPref.user!.id!,
            outletId,
            pageToFetch,
            itemsPerPage,
            null, // category
            null, // paymentReceivedIn
            null, // startDate
            null, // endDate
          ),
          showLoader: !loadMore,
        );

        if (response?.status == 'success') {
          apiOrders = response!.data;

          // Check if we received fewer items than requested
          if (apiOrders.length < itemsPerPage) {
            hasMoreData.value = false;
            debugPrint('📭 No more data available from API');
          } else {
            hasMoreData.value = true;
          }

          // After successful fetch, set current page so next load more requests pageToFetch+1
          if (loadMore && apiOrders.isNotEmpty) {
            currentPage.value = pageToFetch;
          }
        } else {
          // API call failed
          if (loadMore) {
            hasMoreData.value = false;
          }
        }
      } else {
        /// Offline: we have all local data, no "next page"
        hasMoreData.value = false;
        debugPrint('📵 Offline mode - no pagination available');
      }

      /// 🔹 Merge API + Local (avoid duplicates)
      final Map<String, OrderModel> mergedMap = {};

      // Add local orders only on initial load
      if (!loadMore) {
        for (final order in localOrders) {
          mergedMap[order.id] = order;
        }
      }

      // Add API orders (will override local if same ID)
      for (final order in apiOrders) {
        mergedMap[order.id] = order;
      }

      /// 🔹 Closed orders only
      final orders = mergedMap.values
          .where((e) => e.status == 'closed')
          .toList();

      // Sort by date (newest first)
      orders.sort((a, b) {
        final dateA = _parseOrderDate(a.createdAt);
        final dateB = _parseOrderDate(b.createdAt);
        return dateB.compareTo(dateA);
      });

      if (loadMore) {
        // Append new orders (avoid duplicates)
        final newOrders = orders.where((order) {
          return !allOrders.any(
            (existingOrder) => existingOrder.id == order.id,
          );
        }).toList();

        allOrders.addAll(newOrders);
        debugPrint(
          '➕ Added ${newOrders.length} new orders (Total: ${allOrders.length})',
        );
      } else {
        // Replace all orders on initial load or refresh
        allOrders.value = orders;
        debugPrint('🔄 Replaced with ${orders.length} orders');
      }
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      if (loadMore) {
        hasMoreData.value = false;
      }
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
      }
    }
  }

  /// 🔹 Load more orders when scrolling
  Future<void> loadMoreOrders() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      return;
    }

    debugPrint('📥 Loading more orders...');
    await getOrderList(loadMore: true);
  }

  /// 🔹 Pull to refresh
  Future<void> refreshOrders() async {
    debugPrint('🔄 Refreshing orders...');
    currentPage.value = 1;
    hasMoreData.value = true;
    await getOrderList(loadMore: false);
  }

  /// 🔹 Change filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
    debugPrint('🔍 Filter changed to: $filter');
  }

  /// 🔹 Get filtered orders (ALL / LAST 60 MINS)
  List<OrderModel> getFilteredOrders() {
    List<OrderModel> filtered;

    if (selectedFilter.value == 'all') {
      filtered = List.from(allOrders);
    } else {
      final now = DateTime.now();
      final sixtyMinsAgo = now.subtract(const Duration(minutes: 60));

      filtered = allOrders.where((order) {
        final orderDateTime = _parseOrderDate(order.createdAt);
        return orderDateTime.isAfter(sixtyMinsAgo);
      }).toList();
    }

    /// 🔥 Always latest first
    filtered.sort((a, b) {
      final dateA = _parseOrderDate(a.createdAt);
      final dateB = _parseOrderDate(b.createdAt);
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  @override
  void onInit() {
    super.onInit();
    getOrderList();
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
