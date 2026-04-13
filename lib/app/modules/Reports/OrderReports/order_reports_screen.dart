import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Reports/OrderReports/order_reports_controller.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart' as date_util;
import 'package:flutter_modular/flutter_modular.dart';

class OrderReportsScreen extends StatefulWidget {
  const OrderReportsScreen({super.key});

  @override
  State<OrderReportsScreen> createState() => _OrderReportsScreenState();
}

class _OrderReportsScreenState extends State<OrderReportsScreen> {
  final controller = Get.put(OrderReportsController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  /// ✅ FIXED: Better scroll threshold (500px before end instead of 300px)
  void _setupScrollListener() {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // ✅ Trigger load more when user scrolls near the bottom (500px before end)
    // This gives a better user experience
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final threshold = 500.0; // Trigger 500px before the end

      if (currentScroll >= (maxScroll - threshold)) {
        controller.loadMoreOrders();
      }
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  /// Helper method to format order date
  String _formatOrderDate(dynamic dateValue, AppLocalizations loc) {
    try {
      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return loc.invalid_date;
      }
      return date_util.formatDate(date.toString());
    } catch (e) {
      debugPrint('❌ Error formatting date: $e');
      return loc.invalid_date;
    }
  }

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.order_Reports,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final appPref = Get.find<AppPref>();
              if (!hasTrialOrSubscription(appPref)) {
                checkSubscription();
                return;
              }
              controller.exportToExcel();
            },
            icon: Assets.svg.excel.svg(height: 24, width: 24),
            tooltip: 'Export to Excel',
          ),
          IconButton(
            onPressed: () {
              final appPref = Get.find<AppPref>();
              if (!hasTrialOrSubscription(appPref)) {
                checkSubscription();
                return;
              }
              controller.exportToPdf();
            },
            icon: Assets.pdf.image(height: 24, width: 24),
            tooltip: 'Export to PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep desktop layout readable by limiting width.
            final maxWidth = constraints.maxWidth > 1100
                ? 1100.0
                : (constraints.maxWidth > 720 ? 900.0 : constraints.maxWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // Filters Section
                      _buildFiltersSection(loc),

                      // Summary Cards
                      _buildSummaryCards(loc),

                      // Orders List (show loader in list only when changing category or payment type)
                      Expanded(
                        child: controller.isLoadingListOnly.value
                            ? const Center(
                                child: SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : _buildOrdersList(loc),
                      ),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- FILTERS SECTION ----------------
  Widget _buildFiltersSection(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Period and Date Range Row
          Row(
            children: [
              Expanded(child: _buildPeriodSelector(loc)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateRangeSelector(loc)),
            ],
          ),
          const SizedBox(height: 12),
          // Payment Type and Order Type Row
          Row(
            children: [
              Expanded(child: _buildPaymentTypeSelector(loc)),
              const SizedBox(width: 12),
              Expanded(child: _buildOrderTypeSelector(loc)),
            ],
          ),
          const SizedBox(height: 12),
          // Category Selector
          _buildCategorySelector(loc),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations loc) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel(loc.period),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedTimePeriod.value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: controller.getLocalizedTimePeriods(loc).map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      controller.getLocalizedTimePeriodLabel(value, loc),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedTimePeriod.value = newValue;
                    controller.filterByTimePeriod();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel('Date Range'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: controller.selectCustomDateRange,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.formattedDateRange,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Assets.svg.calendar.svg(
                    color: AppColor.grey,
                    height: 18,
                    width: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector(AppLocalizations loc) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel(loc.payment_type),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedPaymentType.value,
                isExpanded: true,
                icon: Assets.svg.bank.svg(
                  color: AppColor.grey,
                  height: 18,
                  width: 18,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: controller.getLocalizedPaymentList(loc).map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      controller.getLocalizedPaymentLabel(value, loc),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedPaymentType.value = newValue;
                    controller.applyAllFilters();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeSelector(AppLocalizations loc) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel(loc.order_type),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedOrderType.value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: controller.getLocalizedOrdersList(loc).map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.getLocalizedOrderLabel(value, loc),
                          ),
                        ),
                        if (value != 'All') ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: controller.getIconFor(value),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return controller.getLocalizedOrdersList(loc).map((value) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.getLocalizedOrderLabel(value, loc),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (value != 'All') ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: controller.getIconFor(value),
                          ),
                        ],
                      ],
                    );
                  }).toList();
                },
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedOrderType.value = newValue;
                    controller.applyAllFilters();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AppLocalizations loc) {
    return Obx(() {
      final categories = controller.availableCategories;
      final current = controller.selectedCategory.value;
      final value = categories.contains(current) ? current : 'All';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel('Category'),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: categories.map((String v) {
                  return DropdownMenuItem<String>(
                    value: v,
                    child: Text(v == 'All' ? loc.all : (v.capitalize ?? v)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.filterByCategory(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[700],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  // ---------------- SUMMARY CARDS ----------------
  Widget _buildSummaryCards(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.receipt_long,
                iconColor: AppColor.primary,
                value: '${controller.totalTransactions}',
                label: loc.no_of_txns,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.currency_rupee,
                iconColor: const Color(0xFF10B981),
                value: '₹${controller.totalSales.toStringAsFixed(0)}',
                label: loc.total_sale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ORDERS LIST ----------------
  Widget _buildOrdersList(AppLocalizations loc) {
    return Obx(() {
      final orders = controller.categoryOrdersL;
      final isLoadingMore = controller.isLoadingMore.value;
      final hasMore = controller.hasMoreData.value;

      if (orders.isEmpty && !isLoadingMore) {
        return _buildEmptyState(loc);
      }

      return RefreshIndicator(
        onRefresh: () async => controller.getOrderList(),
        child: ListView.separated(
          physics: const ClampingScrollPhysics(),
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: orders.length + (isLoadingMore || hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            // ✅ Show loading indicator at the bottom when loading more
            if (index >= orders.length) {
              if (isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }
              // ✅ Show "Load More" button if there's more data but not currently loading
              if (hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.loadMoreOrders(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Load More'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }
              // ✅ Show "No more data" message
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No more orders',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              );
            }

            // ✅ Render order card
            final order = orders[index];
            return _OrderCard(
              order: order,
              index: index,
              loc: loc,
              formatDate: _formatOrderDate,
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/Emptybox.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            loc.no_Orders_Available,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              loc.you_havent_added_any_orders_Please_add_an_order_to_see_item_reports,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ===================== SUMMARY CARD =====================
// =====================================================

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ===================== ORDER CARD =====================
// =====================================================

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final int index;
  final AppLocalizations loc;
  final String Function(dynamic, AppLocalizations) formatDate;

  const _OrderCard({
    required this.order,
    required this.index,
    required this.loc,
    required this.formatDate,
  });

  /// Safe read of payment type from order (handles null, OrderModel, or map with either key).
  static String _getPaymentReceivedIn(dynamic order, AppLocalizations loc) {
    if (order == null) return loc.cash;
    try {
      final v =
          order.paymentReceivedIn ??
          (order is Map
              ? (order['paymentReceivedIn'] ?? order['payment_received_in'])
              : null);
      final s = v?.toString().trim();
      return (s != null && s.isNotEmpty) ? s : loc.cash;
    } catch (_) {
      return loc.cash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = date_util.formatDate(
      order.createdAt.toString(),
      format: 'MMM dd, hh:mm a',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final appPref = Get.find<AppPref>();
            if (!hasTrialOrSubscription(appPref)) {
              checkSubscription();
              return;
            }
            _viewOrderDetails(order);
          },
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColor.primary.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Order Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt,
                            size: 14,
                            color: AppColor.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Amount Row
                Row(
                  children: [
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    // More Menu
                    PopupMenuButton(
                      padding: EdgeInsets.zero,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () async {
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            final appPref = Get.find<AppPref>();
                            if (!hasTrialOrSubscription(appPref)) {
                              checkSubscription();
                              return;
                            }
                            _viewOrderDetails(order);
                          },
                          child: Row(
                            children: [
                              Assets.svg.print.svg(
                                color: Colors.black87,
                                height: 18,
                                width: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(loc.print),
                            ],
                          ),
                        ),
                        // PopupMenuItem(
                        //   onTap: () {
                        //     Future.delayed(
                        //       const Duration(milliseconds: 100),
                        //       () => Get.find<OrderReportsController>()
                        //           .shareOrder(order.id),
                        //     );
                        //   },
                        //   child: Row(
                        //     children: [
                        //       Assets.svg.export.svg(
                        //         color: Colors.black87,
                        //         height: 18,
                        //         width: 18,
                        //       ),
                        //       const SizedBox(width: 8),
                        //       Text(loc.share),
                        //     ],
                        //   ),
                        // ),
                        PopupMenuItem(
                          onTap: () {
                            final appPref = Get.find<AppPref>();
                            if (!hasTrialOrSubscription(appPref)) {
                              checkSubscription();
                              return;
                            }
                            Future.delayed(
                              const Duration(milliseconds: 100),

                              () => Get.find<OrderReportsController>()
                                  .deleteItem(order.id),
                            );
                          },
                          child: Row(
                            children: [
                              Assets.svg.delete.svg(
                                color: Colors.red,
                                height: 18,
                                width: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Details Row
                Row(
                  children: [
                    // Payment Type
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.payment,
                        label: loc.type,
                        value: _getPaymentReceivedIn(order, loc),
                        iconColor: const Color(0xFF10B981),
                      ),
                    ),
                    // Order Source
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.store,
                        label: loc.order_from,
                        value: order.orderFrom,
                        iconWidget: Get.find<OrderReportsController>()
                            .getIconFor(order.orderFrom),
                        iconColor: _getOrderSourceColor(order.orderFrom),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getOrderSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'dine in':
        return const Color(0xFF8B5CF6);
      case 'takeaway':
        return const Color(0xFFF59E0B);
      case 'delivery':
        return const Color(0xFF10B981);
      case 'swiggy':
      case 'zomato':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  void _viewOrderDetails(dynamic order) {
    final loc = AppLocalizations.of(Get.context!)!;
    final paymentReceivedIn = _getPaymentReceivedIn(order, loc);
    Modular.to.pushNamed(
      HomeMainRoutes.invoiceScreen,
      arguments: {
        'invoice': CreateorderRequest(
          billNumber: order.billNumber,
          tableNumber: order.tableNumber,
          customerName: order.customerName,
          phoneNumber: order.phoneNumber,
          discount: order.discount,
          serviceCharge: order.serviceCharge,
          paymentReceivedIn: paymentReceivedIn,
          status: order.status,
          subtotal: order.subtotal,
          totalAmount: order.totalAmount,
          userId: order.userId,
          orderFrom: order.orderFrom,
          totalTax: order.totalTax,
          items: List<OrderItem>.from(
            (order.items ?? <dynamic>[]).map(
              (e) => OrderItem(
                itemId: e.itemId is String
                    ? e.itemId as String
                    : e.itemId.toString(),
                itemName: e.itemName is String
                    ? e.itemName as String
                    : e.itemName.toString(),
                category: e.category is String
                    ? e.category as String
                    : e.category.toString(),
                quantity: e.quantity is int
                    ? e.quantity as int
                    : (e.quantity as num).toInt(),
                salePrice: e.salePrice is double
                    ? e.salePrice as double
                    : (e.salePrice as num).toDouble(),
                gst: e.gst is double
                    ? e.gst as double
                    : (e.gst as num).toDouble(),
              ),
            ),
          ),
        ),
        'orderFrom': order.orderFrom,
      },
    );
    // Get.toNamed(
    //   AppRoute.pdfPreview,
    //   arguments: {
    //     'invoice': CreateorderRequest(
    //       billNumber: order.billNumber,
    //       tableNumber: order.tableNumber,
    //       customerName: order.customerName,
    //       phoneNumber: order.phoneNumber,
    //       discount: order.discount,
    //       serviceCharge: order.serviceCharge,
    //       paymentReceivedIn: paymentReceivedIn,
    //       status: order.status,
    //       subtotal: order.subtotal,
    //       totalAmount: order.totalAmount,
    //       userId: order.userId,
    //       orderFrom: order.orderFrom,
    //       totalTax: order.totalTax,
    //       items: List<OrderItem>.from(
    //         (order.items ?? <dynamic>[]).map(
    //           (e) => OrderItem(
    //             itemId: e.itemId is String
    //                 ? e.itemId as String
    //                 : e.itemId.toString(),
    //             itemName: e.itemName is String
    //                 ? e.itemName as String
    //                 : e.itemName.toString(),
    //             category: e.category is String
    //                 ? e.category as String
    //                 : e.category.toString(),
    //             quantity: e.quantity is int
    //                 ? e.quantity as int
    //                 : (e.quantity as num).toInt(),
    //             salePrice: e.salePrice is double
    //                 ? e.salePrice as double
    //                 : (e.salePrice as num).toDouble(),
    //             gst: e.gst is double
    //                 ? e.gst as double
    //                 : (e.gst as num).toDouble(),
    //           ),
    //         ),
    //       ),
    //     ),
    //     'orderFrom': order.orderFrom,
    //   },
    // );
  }
}

// =====================================================
// ===================== INFO ITEM =====================
// =====================================================

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Widget? iconWidget;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) ...[
              SizedBox(width: 16, height: 16, child: iconWidget),
            ] else ...[
              Icon(icon, size: 14, color: iconColor),
            ],
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }
}
