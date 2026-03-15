import 'dart:async';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/config/config.dart';

class MenuItemController extends BaseController {
  final RxList<ItemData> items = <ItemData>[].obs;
  final RxList<ItemData> allItems = <ItemData>[].obs; // Store all items
  RxList<CategoryData> categories = <CategoryData>[].obs;

  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  var showSearchBar = false.obs;
  Rx<String?> selectedCategoryId = Rx<String?>('none');

  // Item availability map (itemId -> isAvailable)
  final RxMap<String, bool> itemAvailability = <String, bool>{}.obs;

  // Pagination
  var currentPage = 1.obs;
  var hasMoreItems = true.obs;
  var isLoadingMore = false.obs;
  final int itemsPerPage = 10;

  // Initial load done (so UI can show loader until first fetch completes)
  final RxBool initialLoadDone = false.obs;

  // Connectivity listener
  StreamSubscription<bool>? _connectivitySubscription;
  bool _lastConnectivityState = false;
  bool _hasLoadedFromApi = false;

  // Debounce for search API calls
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 400);

  /// ===============================
  /// GET ITEMS (ONLINE / OFFLINE)
  /// ===============================
  Future<void> getItems({
    bool showLoader = true,
    bool forceApiRefresh = false,
    bool loadMore = false,
    String? search,
  }) async {
    final db = AppDatabase();

    try {
      // Prevent multiple simultaneous load more requests
      if (loadMore) {
        if (isLoadingMore.value) {
          debugPrint('⏸️ Already loading more items, skipping...');
          return;
        }
        if (!hasMoreItems.value) {
          debugPrint('⏸️ No more items to load');
          return;
        }
        isLoadingMore.value = true;
      }

      // Reset pagination on fresh load
      if (!loadMore) {
        currentPage.value = 1;
        hasMoreItems.value = true;
      }

      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) {
        debugPrint('❌ No outlet selected');
        return;
      }

      final isOnline = await NetworkUtils.hasInternetConnection();

      debugPrint(
        '🌐 isOnline: $isOnline, loadMore: $loadMore, currentPage: ${currentPage.value}',
      );

      /// ===============================
      /// 🔌 ONLINE → API + SAVE SQLITE
      /// ===============================
      if (isOnline && (!_hasLoadedFromApi || forceApiRefresh || loadMore)) {
        // When searching, don't load more; use higher limit for search results
        if (loadMore && search != null && search.isNotEmpty) {
          isLoadingMore.value = false;
          return;
        }
        final int pageToFetch = loadMore ? currentPage.value + 1 : 1;
        final int limit = (search != null && search.isNotEmpty)
            ? 50
            : itemsPerPage;
        final categoryParam =
            (selectedCategoryId.value != null &&
                selectedCategoryId.value != 'none')
            ? selectedCategoryId.value
            : null;

        debugPrint(
          '🌐 Online → Fetching items from API (page: $pageToFetch, limit: $limit, search: $search)',
        );

        final response = await callApi(
          apiClient.getItems(
            outletId,
            pageToFetch,
            limit,
            categoryParam,
            search?.trim().isEmpty == true ? null : search?.trim(),
            null, // showItem - null to get all
          ),
          showLoader: showLoader && !loadMore,
        );

        if (response?.status == 'success') {
          final receivedItems = response!.data;
          debugPrint(
            '✅ Items received from API - Count: ${receivedItems.length}',
          );

          if (loadMore) {
            // Append new items (avoid duplicates by id)
            final newItems = receivedItems.where((newItem) {
              return !allItems.any(
                (existingItem) => existingItem.id == newItem.id,
              );
            }).toList();

            if (newItems.isNotEmpty) {
              allItems.addAll(newItems);
              debugPrint(
                '➕ Added ${newItems.length} new items (Total: ${allItems.length})',
              );

              // Update availability map for new items
              for (final item in newItems) {
                itemAvailability[item.id] = item.showItem;
              }

              // Increment current page after successful load
              currentPage.value = pageToFetch;
            } else {
              debugPrint('ℹ️ No new items to add (all duplicates)');
            }
          } else {
            // Replace all items on fresh load
            allItems.value = receivedItems;
            currentPage.value = 1;

            // Update availability map
            itemAvailability.clear();
            for (final item in receivedItems) {
              itemAvailability[item.id] = item.showItem;
            }

            debugPrint('🔄 Replaced all items - Total: ${allItems.length}');
          }

          // Determine if there are more items to load
          // Method 1: Check if pagination object exists and has hasNextPage
          if (response.pagination != null &&
              response.pagination!.hasNextPage != null) {
            hasMoreItems.value = response.pagination!.hasNextPage!;
            debugPrint(
              '📄 Pagination info - hasNextPage: ${hasMoreItems.value}',
            );
          }
          // Method 2: If we received exactly itemsPerPage items, there might be more
          else if (receivedItems.length >= itemsPerPage) {
            hasMoreItems.value = true;
            debugPrint(
              '📄 Received ${receivedItems.length} items (>= limit) - Assuming more available',
            );
          }
          // Method 3: If we received fewer items than requested, no more items
          else {
            hasMoreItems.value = false;
            debugPrint(
              '📄 Received ${receivedItems.length} items (< limit) - No more items',
            );
          }

          // Apply current filters (category/search)
          _applyFilters();

          /// Save to SQLite (only on initial load or refresh, not on loadMore, and not when searching)
          if (!loadMore && (search == null || search.isEmpty)) {
            await db.saveItems(allItems, appPref.selectedOutlet!.id!);
            _hasLoadedFromApi = true;
            debugPrint('💾 Items synced to SQLite (${allItems.length})');
          } else if (!loadMore && search != null && search.isNotEmpty) {
            _hasLoadedFromApi = true; // Allow refresh when clearing search
          }
        } else {
          debugPrint('❌ API returned no success status');
          if (loadMore) {
            hasMoreItems.value = false;
          }
        }
      }
      /// ===============================
      /// 📴 OFFLINE → LOAD SQLITE
      /// ===============================
      else if (!isOnline) {
        if (!loadMore) {
          debugPrint('📴 Offline → Loading items from SQLite');
          final localItems = await db.getItems();
          allItems.value = localItems;

          // Update availability map from loaded items
          itemAvailability.clear();
          for (final item in localItems) {
            itemAvailability[item.id] = item.showItem;
          }

          _applyFilters();

          // In offline mode, all items are loaded at once
          hasMoreItems.value = false;
          debugPrint('💾 Loaded ${localItems.length} items from SQLite');
        } else {
          // Can't load more in offline mode
          debugPrint('📴 Offline - Cannot load more items');
          hasMoreItems.value = false;
        }
        _hasLoadedFromApi = false;
      } else {
        // Already loaded from API and not forcing refresh or loading more
        debugPrint('ℹ️ Using cached data - Already loaded from API');
      }
    } catch (e) {
      debugPrint('❌ Item load error: $e');
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_load_items);

      if (loadMore) {
        // On error, assume no more items to prevent infinite retry
        hasMoreItems.value = false;
      }
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
        debugPrint(
          '🏁 Load more completed - hasMore: ${hasMoreItems.value}, isLoading: ${isLoadingMore.value}',
        );
      }
    }
  }

  /// Load more items
  Future<void> loadMoreItems() async {
    debugPrint(
      '📥 loadMoreItems called - hasMore: ${hasMoreItems.value}, isLoading: ${isLoadingMore.value}, currentPage: ${currentPage.value}',
    );

    if (!hasMoreItems.value) {
      debugPrint('⏸️ Cannot load more - hasMore: false');
      return;
    }

    if (isLoadingMore.value) {
      debugPrint('⏸️ Cannot load more - already loading');
      return;
    }

    debugPrint('📥 Loading more items...');
    await getItems(showLoader: false, loadMore: true);
  }

  /// ===============================
  /// APPLY ALL FILTERS (CATEGORY + SEARCH)
  /// ===============================
  void _applyFilters() {
    List<ItemData> filteredItems = allItems;

    // First apply category filter
    if (selectedCategoryId.value != null &&
        selectedCategoryId.value != 'none') {
      filteredItems = filteredItems
          .where(
            (item) =>
                item.category.toLowerCase() ==
                selectedCategoryId.value!.toLowerCase(),
          )
          .toList();
    }

    // Then apply search filter
    if (searchQuery.value.isNotEmpty) {
      filteredItems = filteredItems
          .where(
            (item) => item.itemName.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ),
          )
          .toList();
    }

    items.value = filteredItems;
    debugPrint(
      '🔍 Filters applied - Showing ${items.length} of ${allItems.length} items',
    );
  }

  /// ===============================
  /// CATEGORY SELECTION
  /// ===============================
  void selectCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    _applyFilters();
    debugPrint('📂 Category selected: $categoryId');
  }

  /// ===============================
  /// GET CATEGORIES
  /// ===============================
  Future<void> getCategories() async {
    final response = await callApi(
      apiClient.getCategories(appPref.selectedOutlet!.id!),
      showLoader: false,
    );

    if (response?.status == 'success') {
      debugPrint('📂 Categories loaded');

      List<CategoryData> categoryList = response!.categories;
      categories.clear();
      categories.addAll(categoryList);
      dismissAllAppLoader();
    }
  }

  /// ===============================
  /// TOGGLE SEARCH BAR
  /// ===============================
  void showSearchBarFunction() {
    showSearchBar.value = !showSearchBar.value;
  }

  /// ===============================
  /// TOGGLE ITEM AVAILABILITY (showItem) + API updateItem
  /// ===============================
  Future<void> toggleItemAvailability(String itemId) async {
    final item = allItems.where((e) => e.id == itemId).firstOrNull;
    if (item == null) return;

    final current = itemAvailability[itemId] ?? item.showItem;
    final newShowItem = !current;

    // Optimistically update UI
    itemAvailability[itemId] = newShowItem;

    final request = ItemRequest(
      itemName: item.itemName,
      salePrice: item.salePrice,
      withTax: item.withTax,
      gst: item.gst.toDouble(),
      orderFrom: item.orderFrom ?? 'None',
      userId: item.userId,
      outletId: item.outletId,
      category: item.category,
      itemImage: item.itemImage,
      showItem: newShowItem,
    );

    try {
      final res = await callApi(
        apiClient.updateItem(request, itemId),
        showLoader: false,
      );
      if (res != null && res is Map && res['status'] == 'success') {
        debugPrint('✅ Item availability updated: $itemId -> $newShowItem');
        // Update the item in allItems list if ItemData has copyWith method
        final index = allItems.indexWhere((e) => e.id == itemId);
        if (index != -1) {
          // If ItemData doesn't have copyWith, just update the availability map
          // allItems[index] = allItems[index].copyWith(showItem: newShowItem);
        }
      } else {
        // Revert on failure
        itemAvailability[itemId] = current;
        showError(
          description: res?['message']?.toString() ?? 'Failed to update',
        );
      }
    } catch (e) {
      // Revert on error
      itemAvailability[itemId] = current;
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_load_items);
    }
  }

  /// Whether the item is shown (available)
  bool isItemAvailable(String itemId) {
    if (itemAvailability.containsKey(itemId)) {
      return itemAvailability[itemId]!;
    }
    final item = allItems.where((e) => e.id == itemId).firstOrNull;
    return item?.showItem ?? true;
  }

  /// ===============================
  /// CLEAR SEARCH
  /// ===============================
  void clearSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    searchController.clear();
    searchQuery.value = '';
    _applyFilters();
    // Reload full list from API when online
    getItems(showLoader: false, forceApiRefresh: true);
    debugPrint('🔍 Search cleared');
  }

  /// ===============================
  /// SEARCH FILTER
  /// ===============================
  void filterItemsBySearch(String query) {
    final trimmed = query.trim();
    searchQuery.value = trimmed;
    _applyFilters();

    _searchDebounce?.cancel();
    if (trimmed.isEmpty) {
      getItems(showLoader: false, forceApiRefresh: true);
      return;
    }
    _searchDebounce = Timer(_searchDebounceDuration, () {
      getItems(showLoader: false, forceApiRefresh: true, search: trimmed);
    });
  }

  /// ===============================
  /// ON READY
  /// ===============================
  @override
  void onReady() async {
    super.onReady();
    await getCategories();
    await getItems(showLoader: false);
    initialLoadDone.value = true;

    // Listen to connectivity changes
    _connectivitySubscription = ConnectivityHelper.instance.onConnectivityChange
        .listen((isConnected) {
          if (isConnected && !_lastConnectivityState && !_hasLoadedFromApi) {
            debugPrint('🌐 Internet came back - refreshing items from API');
            getItems(showLoader: false, forceApiRefresh: true);
          }
          _lastConnectivityState = isConnected;
        });

    _lastConnectivityState = ConnectivityHelper.instance.isConnected;
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
