import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/edit_order_widget.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_controller.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter_modular/flutter_modular.dart';

class HoldOrdersScreen extends StatefulWidget {
  const HoldOrdersScreen({super.key});

  @override
  State<HoldOrdersScreen> createState() => _HoldOrdersScreenState();
}

class _HoldOrdersScreenState extends State<HoldOrdersScreen> {
  late final HoldOrdersController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<HoldOrdersController>()
        ? Get.find<HoldOrdersController>()
        : Get.put(HoldOrdersController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getOrderList(forceApiRefresh: true);
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<HoldOrdersController>()) {
      Get.delete<HoldOrdersController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Hold Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [_buildAddOrderButton(), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 1100
                ? 1100.0
                : (constraints.maxWidth > 720 ? 900.0 : constraints.maxWidth);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Expanded(child: _buildOrdersList())],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- ORDER LIST ----------------

  Widget _buildOrdersList() {
    return Obx(() {
      if (controller.allOrders.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async => controller.getOrderList(forceApiRefresh: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200 &&
                controller.hasMoreOrders.value &&
                !controller.isLoadingMore.value) {
              controller.loadMoreOrders();
            }
            return false;
          },
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount:
                controller.allOrders.length +
                (controller.hasMoreOrders.value ? 1 : 0),
            separatorBuilder: (_, index) {
              if (index >= controller.allOrders.length - 1)
                return SizedBox.shrink();
              return const SizedBox(height: 14);
            },
            itemBuilder: (context, index) {
              if (index == controller.allOrders.length) {
                // Load more indicator
                return Obx(
                  () => controller.isLoadingMore.value
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : SizedBox.shrink(),
                );
              }
              final order = controller.allOrders[index];
              return _OrderCard(order: order);
            },
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Hold Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders on hold will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ---------------- ADD ORDER BUTTON ----------------

  Widget _buildAddOrderButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton.icon(
        onPressed: () => Modular.to.pushNamed(HomeMainRoutes.createOrder),
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
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
            onTap: () => _editOrder(order),
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
                      // Hold Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pause_circle,
                              size: 14,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ON HOLD',
                              style: TextStyle(
                                color: const Color(0xFFF59E0B),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
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
                  const SizedBox(height: 8),
                  if ((order.billNumber).trim().isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bill #${order.billNumber}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                      // Edit Button
                      Tooltip(
                        message: 'Edit',
                        child: IconButton(
                          onPressed: () => _editOrder(order),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColor.primary.withOpacity(0.10),
                            foregroundColor: AppColor.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(10),
                            minimumSize: const Size(0, 0),
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

  void _editOrder(OrderModel order) {
    EditOrderBottomSheet.show(
      order: order,
      onUpdate: () {
        Modular.to.pushNamed(
          HomeMainRoutes.createOrder,
          arguments: {'isEdit': true, 'order': order},
        );

        // Get.toNamed(
        //   AppRoute.addOrder,
        //   arguments: {'isEdit': true, 'order': order},
        // );
      },
      onDelete: () {
        // Handle delete
      },
    );
  }
}
