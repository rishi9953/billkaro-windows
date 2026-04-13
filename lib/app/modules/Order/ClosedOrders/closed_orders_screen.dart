import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_controller.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart'
    hide OrderItem;
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter_modular/flutter_modular.dart';

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
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
        title: const Text(
          'Closed Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [_buildAddOrderButton(), const SizedBox(width: 8)],
      ),
      body: const ClosedOrdersContent(),
    );
  }

  Widget _buildAddOrderButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton.icon(
        onPressed: () => Modular.to.navigate(HomeMainRoutes.createOrder),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Order',
          style: TextStyle(
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
    // Always refresh when this screen is opened from dashboard/navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshOrders();
    });
  }

  void _setupScrollListener() {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Trigger load more when user scrolls near the bottom (300px before end)
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300) {
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
                  _buildFilterSection(),
                  Expanded(child: _buildOrdersList()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Obx(() {
        final isAll = controller.selectedFilter.value == 'all';
        final isLast60 = controller.selectedFilter.value == 'last60';

        return ToggleButtons(
          isSelected: [isAll, isLast60],
          borderRadius: BorderRadius.circular(10),
          borderColor: Colors.grey.shade300,
          selectedBorderColor: AppColor.primary,
          fillColor: AppColor.primary.withOpacity(0.10),
          color: Colors.grey.shade700,
          selectedColor: AppColor.primary,
          constraints: const BoxConstraints(minHeight: 44, minWidth: 160),
          onPressed: (index) {
            controller.setFilter(index == 0 ? 'all' : 'last60');
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'All Time',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Last 60 Min',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ---------------- ORDER LIST ----------------
  Widget _buildOrdersList() {
    return Obx(() {
      final orders = controller.getFilteredOrders();

      if (orders.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshOrders,
        child: ListView.separated(
          physics: const ClampingScrollPhysics(),
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: orders.length + 1, // +1 for loading indicator
          separatorBuilder: (_, index) {
            if (index >= orders.length) return const SizedBox.shrink();
            return const SizedBox(height: 14);
          },
          itemBuilder: (context, index) {
            // Loading indicator at the bottom
            if (index == orders.length) {
              return _buildBottomLoader();
            }
            return _OrderCard(order: orders[index]);
          },
        ),
      );
    });
  }

  // Bottom loader widget
  Widget _buildBottomLoader() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        // Show loading spinner
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (!controller.hasMoreData.value &&
          controller.allOrders.isNotEmpty) {
        // Show "No more data" message
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'No more orders',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      } else if (controller.hasMoreData.value &&
          controller.allOrders.isNotEmpty) {
        // Show scroll hint
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Scroll for more',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Closed Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Closed orders will appear here',
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
                              'Table ${order.tableNumber}',
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

                // Order Source
                if (order.orderFrom.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                            '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
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
                    // Print Button
                    Tooltip(
                      message: 'Print',
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
                  ],
                ),
              ],
            ),
          ),
        ),
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

// (Old chip-based filter UI removed in favor of ToggleButtons)
