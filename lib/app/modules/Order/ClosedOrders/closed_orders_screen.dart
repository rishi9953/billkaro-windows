import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart'
    hide OrderItem;
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:billkaro/utils/staff_access.dart';

class ClosedOrdersScreen extends StatelessWidget {
  const ClosedOrdersScreen({super.key});

  void _goBack() {
    if (Modular.to.canPop()) {
      Modular.to.pop();
      return;
    }

    Modular.to.navigate(HomeMainRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
        title: Text(
          loc.closedOrders,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),

        actions: [
          // Refresh button
          IconButton(
            onPressed: () {
              final controller = Get.find<ClosedOrdersController>();
              controller.refreshOrders();
            },
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: const ClosedOrdersContent(),
      floatingActionButton: StaffAccess.canCreateSales
          ? FloatingActionButton.extended(
        onPressed: () => Modular.to.navigate(HomeMainRoutes.createOrder),
        backgroundColor: AppColor.secondaryPrimary,
        foregroundColor: AppColor.white,
        elevation: 4,
        icon: Icon(Icons.add, size: 24),
        label: Text(
          loc.add_Order,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      )
          : null,
    );
  }

  Widget _buildAddOrderButton(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton.icon(
        onPressed: StaffAccess.canCreateSales
            ? () => Modular.to.navigate(HomeMainRoutes.createOrder)
            : null,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          loc.add_Order,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 0),
        ),
      ),
    );
  }
}

class ClosedOrdersContent extends StatefulWidget {
  const ClosedOrdersContent({super.key});

  @override
  State<ClosedOrdersContent> createState() => _ClosedOrdersContentState();
}

class _ClosedOrdersContentState extends State<ClosedOrdersContent> {
  final ClosedOrdersController controller =
      Get.isRegistered<ClosedOrdersController>()
      ? Get.find<ClosedOrdersController>()
      : Get.put(ClosedOrdersController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 500) {
      controller.loadMoreOrders();
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    if (Get.isRegistered<ClosedOrdersController>()) {
      Get.delete<ClosedOrdersController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep content readable on desktop by limiting max width.
          final maxWidth = constraints.maxWidth > 1100
              ? 1100.0
              : (constraints.maxWidth > 720 ? 900.0 : constraints.maxWidth);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFiltersSection(context, loc),
                  Expanded(child: _buildOrdersList(loc)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, AppLocalizations loc) {
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
          Row(
            children: [
              Expanded(child: _buildPeriodSelector(context, loc)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateRangeSelector(context, loc)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPaymentTypeSelector(loc)),
              const SizedBox(width: 12),
              Expanded(child: _buildOrderTypeSelector(loc)),
            ],
          ),
          const SizedBox(height: 12),
          _buildCategorySelector(loc),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, AppLocalizations loc) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel(loc.period),
          const SizedBox(height: 6),
          AppFilterDropdown2<String>(
            value: controller.selectedTimePeriod.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            items: controller.getLocalizedTimePeriods(loc).map((String value) {
              return DropdownItem<String>(
                value: value,
                child: Text(controller.getLocalizedTimePeriodLabel(value, loc)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.selectedTimePeriod.value = newValue;
                controller.filterByTimePeriod(context: context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel('Date Range'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => controller.selectCustomDateRange(context: context),
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
          AppFilterDropdown2<String>(
            value: controller.selectedPaymentType.value,
            iconStyleData: IconStyleData(
              icon: Assets.svg.bank.svg(
                color: AppColor.grey,
                height: 18,
                width: 18,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            items: controller.getLocalizedPaymentList(loc).map((String value) {
              return DropdownItem<String>(
                value: value,
                child: Text(controller.getLocalizedPaymentLabel(value, loc)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.selectedPaymentType.value = newValue;
                controller.filterByPaymentType();
              }
            },
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
          AppFilterDropdown2<String>(
            value: controller.selectedOrderType.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            items: controller.getLocalizedOrdersList(loc).map((String value) {
              return DropdownItem<String>(
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
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.selectedOrderType.value = newValue;
                controller.filterByOrderType();
              }
            },
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
          AppFilterDropdown2<String>(
            value: value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            items: categories.map((String v) {
              return DropdownItem<String>(
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

  // ---------------- ORDER LIST ----------------
  Widget _buildOrdersList(AppLocalizations loc) {
    return Obx(() {
      if (controller.isLoadingListOnly.value) {
        return const Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      final orders = controller.categoryOrdersL.toList();
      final isLoadingMore = controller.isLoadingMore.value;
      final hasMore = controller.hasMoreData.value;

      if (orders.isEmpty && !controller.isLoading.value && !isLoadingMore) {
        return _buildEmptyState(loc);
      }

      if (controller.isLoading.value && orders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: controller.refreshOrders,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: orders.length + (isLoadingMore || hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
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
              if (hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: controller.loadMoreOrders,
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    loc.no_more_orders,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              );
            }
            return _OrderCard(order: orders[index]);
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
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            loc.no_closed_orders,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.closed_orders_empty_hint,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final time = formatDate(
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
                    // Bill Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                            order.billNumber,
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 13,
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

                // Amount and Table Row
                Row(
                  children: [
                    // Total Amount
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    // Table Number (if available)
                    if (order.tableNumber != null &&
                        order.tableNumber!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loc.home_table_number(order.tableNumber!),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Order Source & Payment
                if (order.orderFrom.isNotEmpty ||
                    (order.paymentReceivedIn?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 8),
                  Row(
                    spacing: 10,
                    children: [
                      if (order.orderFrom.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getOrderSourceColor(
                              order.orderFrom,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _getOrderSourceIcon(order.orderFrom),
                              const SizedBox(width: 4),
                              Text(
                                order.orderFrom.toUpperCase(),
                                style: TextStyle(
                                  color: _getOrderSourceColor(order.orderFrom),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (order.paymentReceivedIn?.trim().isNotEmpty ?? false)
                        _buildPaymentBadge(order.paymentReceivedIn!.trim()),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Items Preview
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.order_items_count(order.items.length),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.items
                                .take(2)
                                .map((e) => e.itemName)
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Print + Delete
                    Tooltip(
                      message: loc.print,
                      child: IconButton(
                        onPressed: () => _printOrder(order),
                        icon: const Icon(Icons.print_outlined, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColor.primary.withOpacity(0.10),
                          foregroundColor: AppColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                    if (StaffAccess.canUpdateSales) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: loc.delete_order,
                        child: IconButton(
                          onPressed: () => _confirmDelete(order, loc),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.10),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(OrderModel order, AppLocalizations loc) {
    if (!StaffAccess.ensure(StaffAccess.canUpdateSales)) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.delete_order,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          loc.delete_order_confirm_message,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (Get.isRegistered<ClosedOrdersController>()) {
                Get.find<ClosedOrdersController>().softDeleteOrder(order);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String payment) {
    final paymentColor = _getPaymentColor(payment);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: paymentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payment, size: 14, color: paymentColor),
          const SizedBox(width: 4),
          Text(
            payment.capitalizeFirst ?? payment,
            style: TextStyle(
              color: paymentColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getOrderSourceIcon(String source) {
    switch (source) {
      case 'Delivery':
        return Assets.delivery.image(width: 14, height: 14);
      case 'Dine In':
        return Assets.dineIn.image(width: 14, height: 14);
      case 'Swiggy':
        return Assets.svg.swiggy.svg(width: 14, height: 14);
      case 'Takeaway':
        return Assets.takeaway.image(width: 14, height: 14);
      case 'Zomato':
        return Assets.svg.zomato.svg(width: 14, height: 14);
      default:
        return const Icon(Icons.help_outline, size: 14);
    }
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

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xFF10B981);
      case 'online':
      case 'upi':
        return const Color(0xFF3B82F6);
      case 'card':
      case 'credit':
      case 'debit':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  void _viewOrderDetails(OrderModel order) {
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
          paymentReceivedIn: order.paymentReceivedIn,
          status: order.status,
          subtotal: order.subtotal,
          totalAmount: order.totalAmount,
          userId: order.userId,
          orderFrom: order.orderFrom,
          totalTax: order.totalTax,
          items: order.items
              .map(
                (e) => OrderItem(
                  itemId: e.itemId,
                  itemName: e.itemName,
                  category: e.category,
                  quantity: e.quantity,
                  salePrice: e.salePrice,
                  gst: e.gst,
                ),
              )
              .toList(),
        ),
        'orderFrom': order.orderFrom,
      },
    );
  }

  void _printOrder(OrderModel order) {
    _viewOrderDetails(order);
  }
}
