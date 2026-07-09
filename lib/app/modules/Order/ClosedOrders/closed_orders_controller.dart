import 'package:billkaro/app/Widgets/app_date_picker.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';

class ClosedOrdersController extends BaseController {
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  final RxString selectedTimePeriod = 'All'.obs;
  final RxString selectedPaymentType = 'All'.obs;
  final RxString selectedOrderType = 'All'.obs;
  final RxString selectedCategory = 'All'.obs;

  final RxBool isLoading = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isLoadingListOnly = false.obs;

  int page = 1;
  final int limit = 10;

  final RxList<OrderModel> allOrders = <OrderModel>[].obs;
  final RxList<OrderModel> ordersL = <OrderModel>[].obs;
  final RxList<OrderModel> categoryOrdersL = <OrderModel>[].obs;

  /// Fetch orders from API with active filter params (same as Order Reports).
  Future<void> getOrderList({
    bool loadMore = false,
    bool loaderInListOnly = false,
  }) async {
    try {
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

      if (loadMore && isLoadingMore.value) return;
      if (loadMore && !hasMoreData.value) return;

      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        page = 1;
        hasMoreData.value = true;
      }

      final isOnline = await NetworkUtils.hasInternetConnection();
      final db = AppDatabase();

      if (isOnline) {
        final categoryParam = selectedCategory.value == 'All'
            ? null
            : selectedCategory.value;

        final paymentParam = selectedPaymentType.value == 'All'
            ? null
            : selectedPaymentType.value.toLowerCase();

        final range = selectedDateRange.value;
        final startDateStr = range != null
            ? formatIstDateForApi(range.start)
            : null;
        final endDateStr = range != null
            ? formatIstDateForApi(range.end)
            : null;

        final userId = appPref.ordersApiUserId;
        if (userId == null || userId.isEmpty) {
          showError(description: 'User or outlet information is missing.');
          return;
        }

        debugPrint(
          '🌐 ClosedOrders API → page=$page category=$categoryParam '
          'payment=$paymentParam start=$startDateStr end=$endDateStr',
        );

        final response = await callApi(
          apiClient.getOrders(
            userId,
            outletId,
            page,
            limit,
            categoryParam,
            paymentParam,
            startDateStr,
            endDateStr,
          ),
          showLoader: false,
        );

        if (response?.status == 'success') {
          final rawCount = response!.data.length;
          final newOrders = response.data
              .where((e) => e.status.trim().toLowerCase() == 'closed')
              .toList();

          if (loadMore) {
            allOrders.addAll(newOrders);
          } else {
            allOrders.value = newOrders;
          }

          if (rawCount < limit) {
            hasMoreData.value = false;
          } else {
            hasMoreData.value = true;
            page++;
          }

          await db.insertOrders(newOrders, outletId, isSyncedFromApi: true);
          applyAllFilters();
        } else if (loadMore) {
          hasMoreData.value = false;
        }
      } else {
        final localOrders = await db.getAllOrders(outletId: outletId);
        allOrders.value = localOrders
            .where((e) => e.status.trim().toLowerCase() == 'closed')
            .toList();
        hasMoreData.value = false;
        applyAllFilters();
      }
    } catch (e) {
      debugPrint('❌ Error loading closed orders: $e');
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_load_orders);
      if (loadMore) hasMoreData.value = false;
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

  Future<void> loadMoreOrders() async {
    if (isLoadingMore.value || !hasMoreData.value) return;
    await getOrderList(loadMore: true);
  }

  Future<void> refreshOrders() async {
    selectedTimePeriod.value = 'All';
    selectedDateRange.value = null;
    selectedPaymentType.value = 'All';
    selectedOrderType.value = 'All';
    selectedCategory.value = 'All';
    await getOrderList();
  }

  void applyAllFilters() {
    List<OrderModel> filtered = List.from(allOrders);

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

    if (selectedOrderType.value != 'All') {
      filtered = filtered.where((order) {
        return order.orderFrom.toLowerCase() ==
            selectedOrderType.value.toLowerCase();
      }).toList();
    }

    if (selectedPaymentType.value != 'All') {
      filtered = filtered.where((order) {
        final paymentType = order.paymentReceivedIn?.toLowerCase() ?? '';
        return paymentType == selectedPaymentType.value.toLowerCase();
      }).toList();
    }

    filtered.sort((a, b) {
      final dateA = _parseOrderDate(a.createdAt);
      final dateB = _parseOrderDate(b.createdAt);
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    ordersL.value = filtered;
    applyCategoryFilter();
  }

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

  void applyCategoryFilter() {
    final cat = selectedCategory.value.trim();
    if (cat.isEmpty || cat == 'All' || cat.toLowerCase() == 'none') {
      categoryOrdersL.value = List<OrderModel>.from(ordersL);
      return;
    }

    if (!availableCategories.contains(cat)) {
      selectedCategory.value = 'All';
      categoryOrdersL.value = List<OrderModel>.from(ordersL);
      return;
    }

    categoryOrdersL.value = ordersL.where((order) {
      return order.items.any((i) => i.category.trim() == cat);
    }).toList();
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    page = 1;
    hasMoreData.value = true;
    getOrderList(loaderInListOnly: true);
  }

  void filterByPaymentType() {
    page = 1;
    hasMoreData.value = true;
    getOrderList(loaderInListOnly: true);
  }

  void filterByOrderType() {
    applyAllFilters();
  }

  Future<void> filterByTimePeriod({BuildContext? context}) async {
    if (selectedTimePeriod.value == 'Custom') {
      await selectCustomDateRange(context: context);
      return;
    }

    selectedDateRange.value = istDateRangeForPeriod(selectedTimePeriod.value);
    page = 1;
    hasMoreData.value = true;
    await getOrderList(loaderInListOnly: true);
  }

  Future<void> selectCustomDateRange({BuildContext? context}) async {
    final picked = await showAppDateRangePickerFromGet(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange.value,
    );

    if (picked != null) {
      selectedDateRange.value = picked;
      selectedTimePeriod.value = 'Custom';
      page = 1;
      hasMoreData.value = true;
      await getOrderList(loaderInListOnly: true);
    } else if (selectedTimePeriod.value == 'Custom') {
      selectedTimePeriod.value = 'Today';
      await filterByTimePeriod(context: context);
    }
  }

  String get formattedDateRange {
    final loc = AppLocalizations.of(Get.context!)!;
    if (selectedDateRange.value == null) return loc.select_date;
    final start = selectedDateRange.value!.start;
    final end = selectedDateRange.value!.end;
    return '${_formatDate(start)} TO ${_formatDate(end)}';
  }

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

  List<String> getLocalizedPaymentList(AppLocalizations loc) {
    return ['All', 'Cash', 'UPI', 'PhonePe', 'GooglePay'];
  }

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

  List<String> getLocalizedOrdersList(AppLocalizations loc) {
    return ['All', 'Delivery', 'Dine In', 'Swiggy', 'Takeaway', 'Zomato'];
  }

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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    return '$day/$month/$year';
  }

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

  @override
  void onInit() {
    super.onInit();
    selectedDateRange.value = null;
    ever<List<OrderModel>>(ordersL, (_) => applyCategoryFilter());
  }

  @override
  void onReady() {
    super.onReady();
    getOrderList();
  }
}
