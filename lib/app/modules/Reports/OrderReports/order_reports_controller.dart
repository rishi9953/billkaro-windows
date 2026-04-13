import 'dart:async';
import 'dart:io';

import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class OrderReportsController extends BaseController {
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  final RxList<String> selectedCustomers = <String>[].obs;
  final RxBool isLoading = true.obs;

  final RxBool hasMoreData = true.obs;
  final RxBool isLoadingMore = false.obs;

  /// True when refreshing the list only (e.g. category or payment type change). Show loader in list area only.
  final RxBool isLoadingListOnly = false.obs;

  int page = 1;
  int limit = 10;

  /// Category filter for reports (applies on top of existing filters)
  final RxString selectedCategory = 'All'.obs;

  // All orders from API
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;

  // Filtered orders (displayed in UI)
  final RxList<OrderModel> ordersL = <OrderModel>[].obs;

  /// Orders filtered further by selected category
  final RxList<OrderModel> categoryOrdersL = <OrderModel>[].obs;

  /// Category-wise summary for currently filtered orders (`ordersL`)
  final RxList<CategorySales> categorySummary = <CategorySales>[].obs;

  List<String> ordersList = [
    'All',
    'Delivery',
    'Dine In',
    'Swiggy',
    'Takeaway',
    'Zomato',
  ];

  List<String> paymentList = ['All', 'Cash', 'UPI', 'PhonePe', 'GooglePay'];

  List<String> timePeriods = [
    'All',
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom',
  ];

  /// Default: show all orders (no date filter)
  RxString selectedTimePeriod = 'All'.obs;
  RxString selectedPaymentType = 'All'.obs;
  RxString selectedOrderType = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    // Default: no date range => show all orders
    selectedDateRange.value = null;

    // Keep category results in sync with other filters (for offline mode and after API calls)
    ever<List<OrderModel>>(ordersL, (_) => applyCategoryFilter());

    // Refetch from API when payment type filter changes (loader in list only)
    ever(selectedPaymentType, (_) => getOrderList(loaderInListOnly: true));
  }

  // Connectivity listener
  StreamSubscription<bool>? _connectivitySubscription;
  bool _lastConnectivityState = false;
  bool _hasLoadedFromApi = false;

  @override
  void onReady() {
    super.onReady();
    getOrderList();
  }

  /// 📥 Fetch orders with offline support (page size: 10, load more on scroll)
  /// [loaderInListOnly] when true, only [isLoadingListOnly] is set (loader in list area).
  Future<void> getOrderList({
    bool loadMore = false,
    bool loaderInListOnly = false,
  }) async {
    try {
      // Full-screen loader only on initial load; list-only loader when changing category/payment type
      if (!loadMore) {
        if (loaderInListOnly) {
          isLoadingListOnly.value = true;
        } else {
          isLoading.value = true;
        }
      }

      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(description: loc.no_outlet_selected);
        if (!loadMore) {
          if (loaderInListOnly) {
            isLoadingListOnly.value = false;
          } else {
            isLoading.value = false;
          }
        }
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
      } else {
        // Reset pagination for fresh load
        page = 1;
        hasMoreData.value = true;
      }

      final isOnline = await NetworkUtils.hasInternetConnection();
      final db = AppDatabase();
      debugPrint('🔄 OrderReports isOnline: $isOnline');

      if (isOnline) {
        // Get category parameter: null if "All", otherwise use selected category
        final categoryParam = selectedCategory.value == 'All'
            ? null
            : selectedCategory.value;

        debugPrint(
          '🌐 Internet available → fetching from API (page: $page, category: ${categoryParam ?? "All"})',
        );

        final paymentParam = selectedPaymentType.value == 'All'
            ? null
            : selectedPaymentType.value.toLowerCase();

        final range = selectedDateRange.value;
        final startDateStr = range != null
            ? DateFormat('yyyy-MM-dd').format(range.start)
            : null;
        final endDateStr = range != null
            ? DateFormat('yyyy-MM-dd').format(range.end)
            : null;

        final response = await callApi(
          apiClient.getOrders(
            appPref.user!.id!,
            outletId,
            page,
            limit,
            categoryParam,
            paymentParam,
            startDateStr,
            endDateStr,
          ),
          showLoader: false, // ✅ Changed to false to prevent double loading
        );

        if (response?.status == 'success') {
          final rawCount = response!.data.length;
          final newOrders = response.data
              .where((e) => e.status == 'closed')
              .toList();

          debugPrint(
            '📦 Received $rawCount orders from API (${newOrders.length} closed)',
          );

          if (loadMore) {
            allOrders.addAll(newOrders);
            debugPrint(
              '✅ Added ${newOrders.length} more orders. Total: ${allOrders.length}',
            );
          } else {
            allOrders.value = newOrders;
            debugPrint('✅ Loaded ${newOrders.length} orders');
          }

          // Use raw API count for pagination: if API returned a full page, there may be more
          if (rawCount < limit) {
            hasMoreData.value = false;
            debugPrint(
              '📭 No more orders available (API returned $rawCount < $limit)',
            );
          } else {
            hasMoreData.value = true;
            page++;
            debugPrint('📄 Page incremented to $page');
          }

          // ✅ Save to SQLite
          await db.insertOrders(
            newOrders,
            appPref.selectedOutlet!.id!,
            isSyncedFromApi: true,
          );
          _hasLoadedFromApi = true;
          debugPrint('✅ Orders synced to SQLite');

          // ✅ Apply filters after loading data
          applyAllFilters();
        } else {
          debugPrint('⚠️ API response status not success');
          if (loadMore) {
            hasMoreData.value = false;
          }
        }
      } else {
        debugPrint('📴 No internet → loading from SQLite');
        _hasLoadedFromApi = false;

        final localOrders = await db.getAllOrders(
          outletId: appPref.selectedOutlet!.id!,
        );
        allOrders.value = localOrders
            .where((e) => e.status == 'closed')
            .toList();

        // No pagination for offline mode
        hasMoreData.value = false;

        debugPrint('✅ Loaded ${allOrders.length} orders from SQLite');
        applyAllFilters();
      }
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_load_orders);

      if (loadMore) {
        hasMoreData.value = false;
      }
    } finally {
      if (!loadMore) {
        if (loaderInListOnly) {
          isLoadingListOnly.value = false;
        } else {
          isLoading.value = false;
        }
      }
      if (loadMore) {
        isLoadingMore.value = false;
      }
    }
  }

  /// ✅ Load more orders - called from scroll listener
  Future<void> loadMoreOrders() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      debugPrint(
        '⏭️ Skipping load more: isLoading=${isLoadingMore.value}, hasMore=${hasMoreData.value}',
      );
      return;
    }

    debugPrint('📥 Loading more orders... (page: $page)');
    await getOrderList(loadMore: true);
  }

  /// 🔍 Apply all filters together
  void applyAllFilters() {
    List<OrderModel> filtered = List.from(allOrders);

    // 1️⃣ Filter by Date Range (IST calendar days vs UTC order timestamps)
    if (selectedDateRange.value != null) {
      final start = selectedDateRange.value!.start;
      final end = selectedDateRange.value!.end;

      filtered = filtered.where((order) {
        return isOrderCreatedAtInIstRange(
          order.createdAt.toString(),
          start,
          end,
        );
      }).toList();
    }

    // 2️⃣ Filter by Order Type
    if (selectedOrderType.value != 'All') {
      filtered = filtered.where((order) {
        return order.orderFrom.toLowerCase() ==
            selectedOrderType.value.toLowerCase();
      }).toList();
    }

    // 3️⃣ Filter by Payment Type
    if (selectedPaymentType.value != 'All') {
      filtered = filtered.where((order) {
        final paymentType = order.paymentReceivedIn?.toLowerCase() ?? '';
        return paymentType == selectedPaymentType.value.toLowerCase();
      }).toList();
    }

    // 4️⃣ Filter by Selected Customers
    if (selectedCustomers.isNotEmpty) {
      filtered = filtered.where((order) {
        return selectedCustomers.contains(order.userId);
      }).toList();
    }

    // 5️⃣ Sort by latest first 🔥
    filtered.sort((a, b) {
      final dateA = _parseOrderDate(a.createdAt);
      final dateB = _parseOrderDate(b.createdAt);

      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA); // DESC → latest first
    });

    ordersL.value = filtered;
    applyCategoryFilter();
    _recalculateCategorySummary();

    debugPrint(
      '🔍 Filtered & Sorted: ${ordersL.length} orders out of ${allOrders.length}',
    );
  }

  /// Available categories from currently-filtered orders
  List<String> get availableCategories {
    final set = <String>{};
    for (final order in ordersL) {
      for (final item in order.items) {
        final c = item.category.trim();
        if (c.isNotEmpty) set.add(c);
      }
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  /// Apply selected category on top of `ordersL`
  void applyCategoryFilter() {
    final cat = selectedCategory.value.trim();
    // Treat "None" like "All"
    if (cat.isEmpty || cat == 'All' || cat.toLowerCase() == 'none') {
      categoryOrdersL.value = List<OrderModel>.from(ordersL);
      return;
    }

    // If current selection doesn't exist in the available categories, fallback to All.
    if (!availableCategories.contains(cat)) {
      selectedCategory.value = 'All';
      categoryOrdersL.value = List<OrderModel>.from(ordersL);
      return;
    }

    categoryOrdersL.value = ordersL.where((order) {
      return order.items.any((i) => i.category.trim() == cat);
    }).toList();
  }

  /// Filter by category and reload from API (shows loader in list only)
  void filterByCategory(String category) {
    selectedCategory.value = category;
    // Reset pagination and reload orders from API with category filter
    page = 1;
    hasMoreData.value = true;
    getOrderList(loaderInListOnly: true);
  }

  void _recalculateCategorySummary() {
    final Map<String, CategorySales> byCategory = {};

    for (final order in ordersL) {
      for (final item in order.items) {
        final c = item.category.trim();
        final category = c.isEmpty ? 'none' : c;
        final amount = (item.salePrice) * (item.quantity);

        final existing = byCategory[category];
        if (existing == null) {
          byCategory[category] = CategorySales(
            category: category,
            amount: amount,
            quantity: item.quantity,
          );
        } else {
          byCategory[category] = CategorySales(
            category: category,
            amount: existing.amount + amount,
            quantity: existing.quantity + item.quantity,
          );
        }
      }
    }

    final list = byCategory.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    categorySummary.value = list;
  }

  /// 🕒 Filter by Time Period
  Future<void> filterByTimePeriod() async {
    if (selectedTimePeriod.value == 'Custom') {
      await selectCustomDateRange();
      return;
    }

    DateTime now = DateTime.now();
    DateTimeRange? range;

    switch (selectedTimePeriod.value) {
      case 'All':
        range = null;
        break;
      case 'Today':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;

      case 'This Week':
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        range = DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day),
        );
        break;

      case 'This Month':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
        break;

      case 'This Quarter':
        int currentQuarter = ((now.month - 1) ~/ 3) + 1;
        int startMonth = (currentQuarter - 1) * 3 + 1;
        DateTime startOfQuarter = DateTime(now.year, startMonth, 1);
        range = DateTimeRange(
          start: startOfQuarter,
          end: DateTime(now.year, now.month, now.day),
        );
        break;

      case 'This Year':
        range = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
    }

    selectedDateRange.value = range;
    await getOrderList(); // Refetch from API with startDate/endDate
  }

  /// 📅 Custom date range picker
  Future<void> selectCustomDateRange() async {
    final picked = await _showAdaptiveDateRangePicker(
      initialDateRange: selectedDateRange.value,
    );

    if (picked != null) {
      selectedDateRange.value = picked;
      selectedTimePeriod.value = 'Custom';
      await getOrderList(); // Refetch from API with startDate/endDate
    } else {
      if (selectedTimePeriod.value == 'Custom' &&
          selectedDateRange.value != null) {
        // Keep Custom if already set
      } else if (selectedTimePeriod.value == 'Custom') {
        // If Custom was just selected but cancelled, revert to Today
        selectedTimePeriod.value = 'Today';
        filterByTimePeriod();
      }
    }
  }

  Future<DateTimeRange?> _showAdaptiveDateRangePicker({
    DateTimeRange? initialDateRange,
  }) async {
    final context = Get.context;
    if (context == null) return null;

    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (dialogContext, child) {
        if (child == null) return const SizedBox.shrink();
        if (!isWindows) return child;

        final theme = Theme.of(dialogContext);
        return Theme(
          data: theme.copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColor.primary,
              surface: Colors.white,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 660),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// 👥 Filter by Customers
  void filterByCustomers() {
    final loc = AppLocalizations.of(Get.context!)!;
    showError(description: loc.customer_filter_coming_soon);
  }

  /// 📊 Filter by Order Type
  void filterByOrderList(String value) {
    selectedOrderType.value = value;
    applyAllFilters();
  }

  /// 💳 Filter by Payment Type
  void filterByPaymentType() {
    applyAllFilters();
  }

  // 📈 Computed properties for stats
  int get totalTransactions => ordersL.length;

  double get totalSales =>
      ordersL.fold(0.0, (sum, order) => sum + (order.totalAmount ?? 0.0));

  String get formattedDateRange {
    final loc = AppLocalizations.of(Get.context!)!;
    if (selectedDateRange.value == null) return loc.select_date;
    final start = selectedDateRange.value!.start;
    final end = selectedDateRange.value!.end;
    return '${_formatDate(start)} TO ${_formatDate(end)}';
  }

  /// Get localized time periods list
  List<String> getLocalizedTimePeriods(AppLocalizations loc) {
    return [
      'All',
      'Today',
      'This Week',
      'This Month',
      'This Quarter',
      'This Year',
      'Custom',
    ];
  }

  /// Get localized label for time period
  String getLocalizedTimePeriodLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'All':
        return loc.all;
      case 'Today':
        return loc.today;
      case 'This Week':
        return loc.this_week;
      case 'This Month':
        return loc.this_month;
      case 'This Quarter':
        return loc.this_quarter;
      case 'This Year':
        return loc.this_year;
      case 'Custom':
        return loc.custom;
      default:
        return value;
    }
  }

  /// Get localized payment list
  List<String> getLocalizedPaymentList(AppLocalizations loc) {
    return ['All', 'Cash', 'UPI', 'PhonePe', 'GooglePay'];
  }

  /// Get localized label for payment type
  String getLocalizedPaymentLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'All':
        return loc.all;
      case 'Cash':
        return loc.cash;
      case 'UPI':
        return loc.upi;
      case 'PhonePe':
        return loc.phonepe;
      case 'GooglePay':
        return loc.googlepay;
      default:
        return value;
    }
  }

  /// Get localized orders list
  List<String> getLocalizedOrdersList(AppLocalizations loc) {
    return ['All', 'Delivery', 'Dine In', 'Swiggy', 'Takeaway', 'Zomato'];
  }

  /// Get localized label for order type
  String getLocalizedOrderLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'All':
        return loc.all;
      case 'Delivery':
        return loc.delivery;
      case 'Dine In':
        return loc.dine_in;
      case 'Swiggy':
        return loc.swiggy;
      case 'Takeaway':
        return loc.takeaway;
      case 'Zomato':
        return loc.zomato;
      default:
        return value;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    return '$day/$month/$year';
  }

  /// 🔄 Helper method to parse date from order
  DateTime? _parseOrderDate(dynamic dateValue) {
    try {
      if (dateValue is DateTime) {
        return dateValue;
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
    } catch (e) {
      debugPrint('❌ Error parsing date: $dateValue - $e');
    }
    return null;
  }

  /// 🗑️ Delete order
  Future<void> deleteItem(String id) async {
    try {
      final loc = AppLocalizations.of(Get.context!)!;
      Get.dialog(
        AlertDialog(
          title: Text(loc.delete_order),
          content: Text(loc.are_you_sure_delete_order),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
            TextButton(
              onPressed: () async {
                allOrders.removeWhere((item) => item.id == id);
                ordersL.removeWhere((item) => item.id == id);
                Get.back();
                showSuccess(description: loc.order_removed_successfully);
              },
              child: Text(
                loc.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error deleting order: $e');
    }
  }

  /// 🔄 Refresh orders
  Future<void> refreshOrders() async => getOrderList();

  /// Format date range for export header (null = All / Select date)
  String formatExportDateRange(DateTimeRange? range, AppLocalizations loc) {
    if (range == null) return loc.all;
    return '${_formatDate(range.start)} TO ${_formatDate(range.end)}';
  }

  /// Fetch orders from API for a given date range (for export). Applies same payment/order type filters.
  Future<List<OrderModel>> fetchOrdersForExport(DateTimeRange range) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return [];

    final startDateStr = DateFormat('yyyy-MM-dd').format(range.start);
    final endDateStr = DateFormat('yyyy-MM-dd').format(range.end);
    final paymentParam = selectedPaymentType.value == 'All'
        ? null
        : selectedPaymentType.value.toLowerCase();
    const exportLimit = 500;

    final response = await callApi(
      apiClient.getOrders(
        appPref.user!.id!,
        outletId,
        1,
        exportLimit,
        null,
        paymentParam,
        startDateStr,
        endDateStr,
      ),
      showLoader: false,
    );

    if (response?.status != 'success' || response!.data.isEmpty) {
      return [];
    }

    var list = response.data.where((e) => e.status == 'closed').toList();
    if (selectedOrderType.value != 'All') {
      list = list
          .where(
            (o) =>
                o.orderFrom.toLowerCase() ==
                selectedOrderType.value.toLowerCase(),
          )
          .toList();
    }
    return list;
  }

  /// Show date range dialog then export to Excel or PDF. [isExcel] true = Excel, false = PDF.
  Future<void> showExportDateRangeDialogAndExport(bool isExcel) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final isWindows = Theme.of(Get.context!).platform == TargetPlatform.windows;
    final actionLabel = isExcel ? 'Excel' : 'PDF';

    final useCurrent = await Get.dialog<bool>(
      AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(
              isExcel ? Icons.table_view_rounded : Icons.picture_as_pdf_rounded,
              color: AppColor.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${loc.orders_report} ($actionLabel)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: isWindows ? 460 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.date_range_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${loc.period}: ${formatExportDateRange(selectedDateRange.value, loc)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use current filter or choose a custom date range for export.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        actions: [
          if (isWindows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text(loc.cancel),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => Get.back(result: true),
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: const Text('Use current filter'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      Get.back(result: false);
                      final picked = await _showAdaptiveDateRangePicker(
                        initialDateRange: selectedDateRange.value,
                      );
                      if (picked == null) return;
                      // Fetch orders for chosen range and export
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );
                      final orders = await fetchOrdersForExport(picked);
                      if (Get.isDialogOpen ?? false) Get.back();
                      if (orders.isEmpty) {
                        showError(description: loc.no_orders_to_export);
                        return;
                      }
                      if (isExcel) {
                        await _exportToExcelWithOrders(orders, picked);
                      } else {
                        await _exportToPdfWithOrders(orders, picked);
                      }
                    },
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: const Text('Choose date range'),
                  ),
                ],
              ),
            )
          else ...[
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Use current filter'),
            ),
            FilledButton(
              onPressed: () async {
                Get.back(result: false);
                final picked = await _showAdaptiveDateRangePicker(
                  initialDateRange: selectedDateRange.value,
                );
                if (picked == null) return;
                // Fetch orders for chosen range and export
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                final orders = await fetchOrdersForExport(picked);
                if (Get.isDialogOpen ?? false) Get.back();
                if (orders.isEmpty) {
                  showError(description: loc.no_orders_to_export);
                  return;
                }
                if (isExcel) {
                  await _exportToExcelWithOrders(orders, picked);
                } else {
                  await _exportToPdfWithOrders(orders, picked);
                }
              },
              child: const Text('Choose date range'),
            ),
          ],
        ],
      ),
    );

    if (useCurrent == true) {
      if (ordersL.isEmpty) {
        showError(description: loc.no_orders_to_export);
        return;
      }
      if (isExcel) {
        await _exportToExcelWithOrders(ordersL, selectedDateRange.value);
      } else {
        await _exportToPdfWithOrders(ordersL, selectedDateRange.value);
      }
    }
  }

  Future<void> exportToPdf() async {
    await showExportDateRangeDialogAndExport(false);
  }

  Future<void> _exportToPdfWithOrders(
    List<OrderModel> ordersToExport,
    DateTimeRange? exportDateRange,
  ) async {
    try {
      final loc = AppLocalizations.of(Get.context!)!;
      if (ordersToExport.isEmpty) {
        showError(description: loc.no_orders_to_export);
        return;
      }

      final exportRangeLabel = formatExportDateRange(exportDateRange, loc);

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final totalTxns = ordersToExport.length;
      final totalSalesVal = ordersToExport.fold(
        0.0,
        (sum, o) => sum + (o.totalAmount ?? 0.0),
      );

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      loc.orders_report,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildDottedLine(),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Report Info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${loc.date}: ${formatDate(DateTime.now().toString())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '${loc.period}: $exportRangeLabel',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  if (selectedOrderType.value != 'All') ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${loc.order_type}: ${getLocalizedOrderLabel(selectedOrderType.value, loc)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                  if (selectedPaymentType.value != 'All') ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${loc.payment_type}: ${getLocalizedPaymentLabel(selectedPaymentType.value, loc)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 20),
              _buildDottedLine(),
              pw.SizedBox(height: 15),

              // Table Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        loc.order_id,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        loc.date,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        loc.customer_name,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        loc.type,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        loc.payment_method,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        loc.amount_rupee,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Orders List
              ...ordersToExport.map((order) {
                final orderDate = _parseOrderDate(order.createdAt);
                final dateStr = orderDate != null
                    ? formatDate(orderDate.toString())
                    : '-';

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          order.id?.substring(0, 8) ?? '-',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          dateStr,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          order.customerName ?? loc.guest,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          order.orderFrom ?? '-',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          order.paymentReceivedIn ?? '-',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Rs${(order.totalAmount ?? 0).toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 15),
              _buildDottedLine(),
              pw.SizedBox(height: 15),

              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${loc.total_transactions}:',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '$totalTxns',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${loc.total_sales}:',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Rs${totalSalesVal.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    _buildDottedLine(),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      loc.orders_report_generated(
                        formatDate(DateTime.now().toString()),
                      ),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      Get.back(); // Close loading dialog
      await _showPdfOptionsDialog(pdf, loc);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_generate_pdf}: $e');
      debugPrint('❌ PDF Generation Error: $e');
    }
  }

  /// Show PDF options dialog
  Future<void> _showPdfOptionsDialog(
    pw.Document pdf,
    AppLocalizations loc,
  ) async {
    await Get.dialog(
      AlertDialog(
        title: Text(loc.orders_report_pdf),
        content: Text(loc.choose_an_option),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _openPdf(pdf);
            },
            child: Text(loc.open),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _printPdf(pdf);
            },
            child: Text(loc.print),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _savePdf(pdf);
            },
            child: Text(loc.save),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _sharePdf(pdf);
            },
            child: Text(loc.share),
          ),
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
        ],
      ),
    );
  }

  /// Print PDF
  Future<void> _printPdf(pw.Document pdf) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_print_pdf}: $e');
      debugPrint('❌ Print Error: $e');
    }
  }

  /// Save PDF to Downloads folder
  Future<void> _savePdf(pw.Document pdf) async {
    try {
      final savePath = await DownloadPathUtil.resolveSaveDirectory(
        preferredPath: appPref.downloadPath,
      );
      await Directory(savePath).create(recursive: true);

      final filePath =
          '$savePath/orders_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      final loc = AppLocalizations.of(Get.context!)!;
      showSuccess(description: loc.pdf_saved_to_downloads);
    } catch (e) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_save_pdf}: $e');
      debugPrint('❌ Save Error: $e');
    }
  }

  /// Share PDF
  Future<void> _sharePdf(pw.Document pdf) async {
    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'orders_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_share_pdf}: $e');
      debugPrint('❌ Share Error: $e');
    }
  }

  /// Open PDF file
  Future<void> _openPdf(pw.Document pdf) async {
    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final savePath = await DownloadPathUtil.resolveSaveDirectory(
        preferredPath: appPref.downloadPath,
      );
      await Directory(savePath).create(recursive: true);

      final filePath =
          '$savePath/orders_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      Get.back(); // Close loading

      // Open the file
      final result = await OpenFile.open(filePath);
      final loc = AppLocalizations.of(Get.context!)!;

      if (result.type == ResultType.done) {
        showSuccess(description: loc.pdf_opened_successfully);
      } else if (result.type == ResultType.noAppToOpen) {
        showError(description: loc.no_app_found_to_open_pdf);
      } else {
        showError(description: '${loc.failed_to_open_pdf}: ${result.message}');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_open_pdf}: $e');
      debugPrint('❌ Open Error: $e');
    }
  }

  /// Build dotted line separator
  pw.Widget _buildDottedLine() {
    return pw.Container(
      height: 1,
      child: pw.LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 4.0;
          final dashSpace = 3.0;
          final dashCount = (constraints!.maxWidth / (dashWidth + dashSpace))
              .floor();

          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return pw.Container(
                width: dashWidth,
                height: 1,
                color: PdfColors.grey400,
              );
            }),
          );
        },
      ),
    );
  }

  /// 📤 Export order report to Excel. Entry point shows date range dialog first.
  Future<void> exportToExcel() async {
    await showExportDateRangeDialogAndExport(true);
  }

  /// Internal: export given orders to Excel with optional date range for header.
  Future<void> _exportToExcelWithOrders(
    List<OrderModel> ordersToExport,
    DateTimeRange? exportDateRange,
  ) async {
    try {
      final loc = AppLocalizations.of(Get.context!)!;
      if (ordersToExport.isEmpty) {
        showError(description: loc.no_orders_to_export);
        return;
      }

      final exportRangeLabel = formatExportDateRange(exportDateRange, loc);
      final totalTxns = ordersToExport.length;
      final totalSalesVal = ordersToExport.fold(
        0.0,
        (sum, o) => sum + (o.totalAmount ?? 0.0),
      );

      // -------------------------------
      // Permissions Handling
      // -------------------------------
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt < 33) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            await Permission.storage.request();
          }
        }
      }

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // -------------------------------
      // Create Workbook
      // -------------------------------
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = "Orders Report";

      // Header Style
      final Style headerStyle = workbook.styles.add('header');
      headerStyle.bold = true;
      headerStyle.backColor = '#4472C4';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.hAlign = HAlignType.center;

      // Title
      sheet.getRangeByName('A1:J1').merge();
      sheet.getRangeByName('A1').setText(loc.orders_report);
      sheet.getRangeByName('A1').cellStyle
        ..bold = true
        ..fontSize = 16
        ..hAlign = HAlignType.center;

      // Filters Info (date range + order type + payment type)
      sheet.getRangeByName('A2:J2').merge();
      sheet
          .getRangeByName('A2')
          .setText(
            '${loc.period}: $exportRangeLabel | ${loc.order_type}: ${getLocalizedOrderLabel(selectedOrderType.value, loc)} | ${loc.payment_type}: ${getLocalizedPaymentLabel(selectedPaymentType.value, loc)}',
          );
      sheet.getRangeByName('A2').cellStyle.italic = true;

      // -------------------------------
      // Table Headers
      // -------------------------------
      final headers = [
        loc.order_id,
        loc.date_time,
        loc.order_type,
        loc.customer_id,
        loc.customer_name,
        loc.customer_phone,
        loc.service_charge_rupee,
        loc.payment_method,
        loc.amount_rupee,
        loc.status,
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(4, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // -------------------------------
      // Fill Data
      // -------------------------------
      for (int i = 0; i < ordersToExport.length; i++) {
        final order = ordersToExport[i];
        final row = i + 5;

        sheet.getRangeByIndex(row, 1).setText(order.id ?? "-");

        // Date
        final date = DateTime.tryParse(order.createdAt!);
        if (date != null) {
          sheet.getRangeByIndex(row, 2).setDateTime(date);
          sheet.getRangeByIndex(row, 2).numberFormat = 'dd/MM/yyyy hh:mm AM/PM';
        } else {
          sheet.getRangeByIndex(row, 2).setText("-");
        }

        sheet.getRangeByIndex(row, 3).setText(order.orderFrom ?? "-");
        sheet.getRangeByIndex(row, 4).setText(order.userId ?? "-");
        sheet.getRangeByIndex(row, 5).setText(order.customerName ?? loc.guest);
        sheet.getRangeByIndex(row, 6).setText(order.phoneNumber ?? "-");

        // Service Charge
        sheet.getRangeByIndex(row, 7).setNumber(order.serviceCharge ?? 0);
        sheet.getRangeByIndex(row, 7).numberFormat = "₹#,##0.00";

        // Payment Method (FIXED column index 8)
        sheet.getRangeByIndex(row, 8).setText(order.paymentReceivedIn ?? '-');

        // Amount (FIXED column index 9)
        sheet.getRangeByIndex(row, 9).setNumber(order.totalAmount ?? 0);
        sheet.getRangeByIndex(row, 9).numberFormat = "₹#,##0.00";

        // Status (column 10) - Keep as is, status is usually from API
        sheet.getRangeByIndex(row, 10).setText(order.status ?? '-');

        // Alternating row color
        if (i % 2 == 1) {
          sheet.getRangeByIndex(row, 1, row, 10).cellStyle.backColor =
              "#F2F2F2";
        }
      }

      // -------------------------------
      // Summary Section
      // -------------------------------
      final summaryRow = ordersToExport.length + 6;

      sheet
          .getRangeByIndex(summaryRow, 8)
          .setText("${loc.total_transactions}:");
      sheet.getRangeByIndex(summaryRow, 9).setNumber(totalTxns.toDouble());
      sheet.getRangeByIndex(summaryRow, 9).cellStyle.bold = true;

      sheet.getRangeByIndex(summaryRow + 1, 8).setText("${loc.total_sales}:");
      sheet.getRangeByIndex(summaryRow + 1, 9).setNumber(totalSalesVal);
      sheet.getRangeByIndex(summaryRow + 1, 9).numberFormat = "₹#,##0.00";
      sheet.getRangeByIndex(summaryRow + 1, 9).cellStyle
        ..bold = true
        ..backColor = "#FFEB9C";

      // Auto-fit columns
      for (int i = 1; i <= 10; i++) {
        sheet.autoFitColumn(i);
      }

      // Borders
      sheet.getRangeByIndex(4, 1, summaryRow + 1, 10).cellStyle.borders.all
        ..lineStyle = LineStyle.thin
        ..color = '#D3D3D3';

      // Save file
      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final saveDir = Directory(
        await DownloadPathUtil.resolveSaveDirectory(
          preferredPath: appPref.downloadPath,
        ),
      );

      if (!saveDir.existsSync()) {
        saveDir.createSync(recursive: true);
      }

      String fileName =
          'BillKaro_Orders_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      String fullPath = '${saveDir.path}/$fileName';

      final file = File(fullPath);
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();
      showSuccess(description: loc.excel_saved_to_downloads);

      final openResult = await OpenFile.open(fullPath);
      if (openResult.type != ResultType.done) {
        debugPrint(
          '⚠️ Excel saved but could not auto-open: ${openResult.message}',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_export}: $e');

      debugPrint("❌ EXPORT ERROR: $e");
    }
  }

  /// 🖨️ Print & Share
  void printOrder(String orderId) {
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(description: loc.printed_order(orderId));
  }

  void shareOrder(String orderId) {
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(description: loc.shared_order(orderId));
  }

  /// 🎨 Get icon for order type
  Widget getIconFor(String value) {
    switch (value) {
      case 'Delivery':
        return Assets.delivery.image(width: 24, height: 24);
      case 'Dine In':
        return Assets.dineIn.image(width: 24, height: 24);
      case 'Swiggy':
        return Assets.svg.swiggy.svg(width: 24, height: 24);
      case 'Takeaway':
        return Assets.takeaway.image(width: 24, height: 24);
      case 'Zomato':
        return Assets.svg.zomato.svg(width: 24, height: 24);
      default:
        return const SizedBox();
    }
  }
}

class CategorySales {
  final String category;
  final double amount;
  final int quantity;

  const CategorySales({
    required this.category,
    required this.amount,
    required this.quantity,
  });
}
