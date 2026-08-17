import 'dart:async';
import 'package:billkaro/app/services/itemfileservice.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/bulk_delete_request.dart';
import 'package:billkaro/app/services/Modals/addItem/bulk_item_request.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_import_file_dialog.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_import_preview_dialog.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_products_template_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';
import 'package:billkaro/utils/staff_access.dart';

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

  // True while items are being fetched after a category change
  final RxBool isCategoryLoading = false.obs;

  // Multi-select delete
  final RxBool isSelectionMode = false.obs;
  final RxList<String> selectedItemIds = <String>[].obs;
  final RxBool isDeletingItems = false.obs;

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
            ? _categoryNameForApi(selectedCategoryId.value!)
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
            null, // isRecommended - null to get all
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

    if (searchQuery.value.isNotEmpty) {
      debugPrint('⏸️ Cannot load more while searching');
      return;
    }

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
  /// Resolves chip id (lowercased) to the stored categoryName for API filters.
  String _categoryNameForApi(String categoryId) {
    final match = categories.firstWhereOrNull(
      (c) => c.categoryName.toLowerCase() == categoryId.toLowerCase(),
    );
    return match?.categoryName ?? categoryId;
  }

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
  Future<void> selectCategory(String? categoryId) async {
    if (selectedCategoryId.value == categoryId) return;

    selectedCategoryId.value = categoryId;
    currentPage.value = 1;
    hasMoreItems.value = true;
    isCategoryLoading.value = true;
    items.clear();

    debugPrint('📂 Category selected: $categoryId');
    try {
      await getItems(showLoader: false, forceApiRefresh: true);
    } finally {
      isCategoryLoading.value = false;
    }
  }

  Map<String, dynamic> buildAddItemArgs() {
    final args = <String, dynamic>{'isEdit': false};
    final id = selectedCategoryId.value;
    if (id != null && id != 'none') {
      final category = categories.firstWhereOrNull(
        (c) => c.categoryName.toLowerCase() == id.toLowerCase(),
      );
      args['category'] = category?.categoryName ?? id;
    }
    return args;
  }

  /// ===============================
  /// GET CATEGORIES
  /// ===============================
  Future<void> getCategories() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    final loaded = await OfflineCategoryLoader.load(
      outletId: outletId,
      fetchFromApi: () =>
          callApi(apiClient.getCategories(outletId), showLoader: false),
    );

    categories.clear();
    categories.addAll(loaded);
    dismissAllAppLoader();
    debugPrint('📂 Categories loaded (${loaded.length})');
  }

  /// Persists item categories that exist on items but not in the categories API
  /// (combo meals previously saved without creating the "combo" category).
  Future<void> ensureMissingItemCategories() async {
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null || allItems.isEmpty) return;

    final known = {
      for (final c in categories) c.categoryName.trim().toLowerCase(),
    };
    final missing = <String>{};
    for (final item in allItems) {
      final name = item.category.trim();
      final key = name.toLowerCase();
      if (name.isEmpty || key == 'none' || known.contains(key)) continue;
      missing.add(key);
    }
    if (missing.isEmpty) return;

    var didCreate = false;
    for (final name in missing) {
      final response = await callApi(
        apiClient.addCategory(outletId, {
          'userId': userId,
          'outletId': outletId,
          'categoryName': name,
        }),
        showLoader: false,
        apiErrorHandler: (_) async => true,
      );
      if (response is Map && response['status'] == 'success') {
        didCreate = true;
      }
    }
    if (didCreate) await getCategories();
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
    if (!StaffAccess.ensure(StaffAccess.canUpdateProducts)) return;
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
        final loc = AppLocalizations.of(Get.context!)!;
        showError(
          description: res?['message']?.toString() ?? loc.failed_to_update_item,
        );
      }
    } catch (e) {
      // Revert on error
      itemAvailability[itemId] = current;
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_update_item);
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
  /// MULTI-SELECT DELETE
  /// ===============================
  void toggleSelectionMode() {
    if (isSelectionMode.value) {
      exitSelectionMode();
    } else {
      isSelectionMode.value = true;
    }
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedItemIds.clear();
  }

  void toggleItemSelection(String itemId) {
    if (selectedItemIds.contains(itemId)) {
      selectedItemIds.remove(itemId);
    } else {
      selectedItemIds.add(itemId);
    }
  }

  bool isItemSelected(String itemId) => selectedItemIds.contains(itemId);

  void selectAllVisibleItems() {
    selectedItemIds.assignAll(items.map((e) => e.id));
  }

  void clearItemSelection() => selectedItemIds.clear();

  Future<void> deleteItem(ItemData item) async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteProducts)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    final name = item.itemName.trim();
    final displayName = name.isEmpty ? loc.this_item : name;
    final shouldDelete =
        await Get.dialog<bool>(
          AlertDialog(
            title: Text(loc.delete_item_title),
            content: Text(loc.delete_item_named_confirm(displayName)),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(loc.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    await _deleteItemsByIds([item.id.trim()], clearSelection: false);
  }

  Future<void> deleteSelectedItems() async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteProducts)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    if (selectedItemIds.isEmpty) {
      showError(description: loc.select_at_least_one_item_to_delete);
      return;
    }

    final count = selectedItemIds.length;
    final shouldDelete =
        await Get.dialog<bool>(
          AlertDialog(
            title: Text(loc.delete_items_title),
            content: Text(loc.delete_items_confirm(count)),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(loc.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    final ids = selectedItemIds.map((id) => id.trim()).toList();
    await _deleteItemsByIds(ids, clearSelection: true);
  }

  Future<void> _deleteItemsByIds(
    List<String> ids, {
    required bool clearSelection,
  }) async {
    if (ids.isEmpty) return;
    final loc = AppLocalizations.of(Get.context!)!;

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }

    isDeletingItems.value = true;
    showAppLoader();
    try {
      final request = BulkDeleteRequest(outletId: outletId, itemIds: ids);
      final res = await callApi(
        apiClient.deleteBulkItems(request),
        showLoader: false,
      );

      if (res != null && res is Map && res['status'] == 'success') {
        for (final id in ids) {
          allItems.removeWhere((e) => e.id == id);
          items.removeWhere((e) => e.id == id);
          itemAvailability.remove(id);
        }
        if (clearSelection) {
          exitSelectionMode();
        }
        _applyFilters();
        await getItems(showLoader: false, forceApiRefresh: true);
        showSuccess(description: loc.items_deleted_successfully(ids.length));
      } else {
        final message = res is Map ? res['message']?.toString() : null;
        showError(
          description: message?.isNotEmpty == true
              ? message!
              : loc.failed_to_delete_selected_items,
        );
      }
    } catch (e) {
      showError(description: loc.failed_to_delete_items_error(e.toString()));
    } finally {
      isDeletingItems.value = false;
      dismissAllAppLoader();
    }
  }

  /// ===============================
  /// IMPORT FROM FILE (Excel .xlsx)
  /// ===============================
  Future<void> importFromFile() async {
    if (!StaffAccess.ensure(StaffAccess.canImportExportProducts)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }

    final shouldPickFile = await showMenuImportFileDialog();
    if (shouldPickFile != true) return;

    const typeGroup = XTypeGroup(
      label: 'Excel',
      extensions: ['xlsx'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    if (!file.path.toLowerCase().endsWith('.xlsx')) {
      showError(description: loc.failed_to_read_file_error('Only .xlsx files are supported.'));
      return;
    }

    List<ItemImportRow> rows;
    try {
      showAppLoader();
      rows = ItemFileService.parseSpreadsheet(file.path);
    } catch (e) {
      showError(description: loc.failed_to_read_file_error(e.toString()));
      return;
    } finally {
      dismissAllAppLoader();
    }

    if (rows.isEmpty) {
      showError(description: loc.no_valid_import_rows);
      return;
    }

    final fileName = file.name;
    final previewRows = await showMenuImportPreviewDialog(
      fileName: fileName.isNotEmpty ? fileName : loc.import_products_excel,
      items: rows
          .map(
            (row) => MenuImportPreviewRow(
              name: row.name,
              price: row.price,
              category: row.category,
              gst: row.gst,
              withTax: row.withTax,
              imageUrl: row.imageUrl,
            ),
          )
          .toList(),
    );
    if (previewRows == null) return;

    showAppLoader();
    try {
      final request = BulkItemRequest(
        userId: userId,
        outletId: outletId,
        items: previewRows
            .map(
              (row) {
                final cat = row.category.trim();
                final normalizedCategory = cat.isEmpty || cat.toLowerCase() == 'none'
                    ? 'none'
                    : cat.toLowerCase();
                return BulkItemEntry(
                  itemName: row.name,
                  salePrice: row.price,
                  withTax: row.withTax,
                  gst: row.gst,
                  orderFrom: 'None',
                  category: normalizedCategory,
                  showItem: row.isAvailable,
                  itemImage: row.imageUrl,
                );
              },
            )
            .toList(),
      );
      final res = await callApi(
        apiClient.addBulkItem(request),
        showLoader: false,
      );

      await getCategories();
      await getItems(showLoader: false, forceApiRefresh: true);

      if (res != null && res is Map && res['status'] == 'success') {
        final count = previewRows.length;
        showSuccess(description: loc.items_imported_successfully(count));
      } else {
        final message = res is Map ? res['message']?.toString() : null;
        showError(
          description: message?.isNotEmpty == true
              ? message!
              : loc.failed_to_import_items,
        );
      }
    } catch (e) {
      showError(description: loc.failed_to_import_file_error(e.toString()));
    } finally {
      dismissAllAppLoader();
    }
  }

  /// ===============================
  /// EXPORT TO FILE (Excel .xlsx)
  /// ===============================
  Future<List<ItemData>> _fetchAllItemsForExport() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return [];

    final isOnline = await NetworkUtils.hasInternetConnection();
    if (!isOnline) {
      return AppDatabase().getItems(outletId: outletId);
    }

    const pageSize = 100;
    final fetched = <ItemData>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final response = await callApi(
        apiClient.getItems(
          outletId,
          page,
          pageSize,
          null,
          null,
          null,
          null,
        ),
        showLoader: false,
      );

      if (response?.status != 'success') break;

      final batch = response!.data;
      if (batch.isEmpty) break;

      for (final item in batch) {
        if (!fetched.any((existing) => existing.id == item.id)) {
          fetched.add(item);
        }
      }

      final pagination = response.pagination;
      if (pagination?.hasNextPage != null) {
        hasMore = pagination!.hasNextPage!;
      } else {
        hasMore = batch.length >= pageSize;
      }
      page++;
    }

    return fetched;
  }

  Future<void> exportToFile() async {
    if (!StaffAccess.ensure(StaffAccess.canImportExportProducts)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }

    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }

    final shouldExport = await showMenuExportFileDialog();
    if (shouldExport != true) return;

    try {
      showAppLoader();
      final itemsToExport = await _fetchAllItemsForExport();
      if (itemsToExport.isEmpty) {
        showError(description: loc.no_items_to_export);
        return;
      }
      await MenuProductsTemplateService.exportItems(itemsToExport);
    } catch (e) {
      showError(description: '${loc.failed_to_export}: $e');
    } finally {
      dismissAllAppLoader();
    }
  }

  /// ===============================
  /// DOWNLOAD PRODUCTS TEMPLATE
  /// ===============================
  Future<void> downloadProductsTemplate() async {
    await MenuProductsTemplateService.downloadTemplate();
  }

  void refreshItems() {
    getItems(showLoader: true, forceApiRefresh: true);
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
    await ensureMissingItemCategories();
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
