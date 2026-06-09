import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CustomerDetailsController extends BaseController {
  static const int pageLimit = 10;

  final customerName = ''.obs;
  final phoneNumber = ''.obs;
  final loyaltyDiscount = 0.0.obs;
  final avgOrder = 0.0.obs;
  final totalDiscount = 0.0.obs;
  final totalVisits = 0.obs;
  final orderValue = 0.0.obs;
  final orders = <CustomerLastOrder>[].obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final totalOrders = 0.obs;
  final isLoading = true.obs;
  final ordersLoading = false.obs;
  final loadError = ''.obs;
  CustomerData? customer;
  CustomerLastOrder? lastOrder;

  @override
  void onInit() {
    final dynamic rawArgs = Get.arguments ?? Modular.args.data;
    if (rawArgs is CustomerData) {
      customer = rawArgs;
      customerName.value = rawArgs.customerName;
      phoneNumber.value = rawArgs.phoneNumber;
      loyaltyDiscount.value =
          double.tryParse(rawArgs.loyalityDiscount.toString()) ?? 0.0;
    } else if (rawArgs != null) {
      debugPrint(
        '[CustomerDetailsController] Unexpected args type: ${rawArgs.runtimeType}',
      );
    }
    super.onInit();
    loadCustomerDetails();
  }

  Future<void> loadCustomerDetails({int page = 1, bool initial = true}) async {
    final customerId = customer?.id;
    final outletId = appPref.selectedOutlet?.id;
    if (customerId == null || outletId == null) {
      loadError.value =
          outletId == null ? 'No outlet selected' : 'Invalid customer';
      isLoading.value = false;
      return;
    }

    if (initial) {
      isLoading.value = true;
    } else {
      ordersLoading.value = true;
    }
    loadError.value = '';

    try {
      final response = await callApi(
        apiClient.getRegularCustomerDetails(
          outletId,
          customerId,
          page,
          pageLimit,
        ),
        showLoader: false,
      );

      if (response?.status == 'success') {
        final data = response!.data;
        customer = data.customer;
        customerName.value = data.customer.customerName;
        phoneNumber.value = data.customer.phoneNumber;
        loyaltyDiscount.value =
            double.tryParse(data.customer.loyalityDiscount.toString()) ?? 0.0;
        avgOrder.value = data.stats.avgOrder;
        totalDiscount.value = data.stats.totalDiscount;
        totalVisits.value = data.stats.totalVisits;
        orderValue.value = data.stats.orderValue;
        orders.value = data.orders;
        lastOrder = data.lastOrder;
        currentPage.value = data.pagination.page;
        totalPages.value = data.pagination.totalPages;
        totalOrders.value = data.pagination.totalOrders;
      } else {
        loadError.value = 'Unable to load customer details.';
      }
    } catch (e) {
      debugPrint('Customer details error: $e');
      loadError.value = 'Unable to load customer details. Please try again.';
    } finally {
      isLoading.value = false;
      ordersLoading.value = false;
    }
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages.value || page == currentPage.value) {
      return;
    }
    await loadCustomerDetails(page: page, initial: false);
  }

  int orderRowNumber(int index) {
    return ((currentPage.value - 1) * pageLimit) + index + 1;
  }

  String get ordersRangeLabel {
    if (totalOrders.value == 0) return 'No orders';
    final start = ((currentPage.value - 1) * pageLimit) + 1;
    final end = start + orders.length - 1;
    return 'Showing $start-$end of ${totalOrders.value}';
  }

  List<int> get visiblePageNumbers {
    final total = totalPages.value;
    final current = currentPage.value;
    if (total <= 7) {
      return List.generate(total, (index) => index + 1);
    }

    final pages = <int>{1, total, current};
    if (current > 1) pages.add(current - 1);
    if (current < total) pages.add(current + 1);
    if (current <= 3) pages.addAll([2, 3]);
    if (current >= total - 2) pages.addAll([total - 1, total - 2]);

    return pages.where((page) => page >= 1 && page <= total).toList()..sort();
  }

  String get customerInitial {
    final name = customerName.value.trim();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  String formatOrderDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/${date.year} • $hour:$minute';
    } catch (_) {
      return raw;
    }
  }
}
