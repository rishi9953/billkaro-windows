import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/edit_order_widget.dart';
import 'package:billkaro/utils/staff_access.dart';
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.hold_orders_title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          // Refresh Button
          IconButton(
            onPressed: () => controller.getOrderList(forceApiRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
          ),
        ],
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
                  children: [Expanded(child: _buildOrdersList(loc))],
                ),
              ),
            );
          },
        ),
      ),
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

  // ---------------- ORDER LIST ----------------

  Widget _buildOrdersList(AppLocalizations loc) {
    return Obx(() {
      if (controller.allOrders.isEmpty) {
        return _buildEmptyState(loc);
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

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            loc.no_hold_orders,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.hold_orders_empty_hint,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ---------------- ADD ORDER BUTTON ----------------

  Widget _buildAddOrderButton(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton.icon(
        onPressed: () => Modular.to.pushNamed(HomeMainRoutes.createOrder),
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
            onTap: StaffAccess.canUpdateSales
                ? () => _editOrder(order)
                : null,
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
                              loc.on_hold_badge,
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
                          loc.home_bill_number(order.billNumber),
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
                      // Edit + Delete
                      if (StaffAccess.canUpdateSales) ...[
                        Tooltip(
                          message: loc.edit,
                          child: IconButton(
                            onPressed: () => _editOrder(order),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColor.primary.withOpacity(0.10),
                              foregroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                              minimumSize: const Size(0, 0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: loc.delete_order,
                          child: IconButton(
                            onPressed: () => _confirmDelete(order, loc),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.red.withOpacity(0.10),
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                              minimumSize: const Size(0, 0),
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
      ),
    );
  }

  void _confirmDelete(OrderModel order, AppLocalizations loc) {
    if (!StaffAccess.ensure(StaffAccess.canUpdateSales)) return;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.white,
            elevation: 16,
            shadowColor: Colors.black.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.delete_order,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loc.delete_order_confirm_message,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            loc.cancel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            if (Get.isRegistered<HoldOrdersController>()) {
                              Get.find<HoldOrdersController>()
                                  .softDeleteOrder(order);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            loc.delete,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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
      barrierDismissible: true,
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
    if (!StaffAccess.ensure(StaffAccess.canUpdateSales)) return;
    EditOrderDialog.show(
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
        if (Get.isRegistered<HoldOrdersController>()) {
          Get.find<HoldOrdersController>().softDeleteOrder(order);
        }
      },
    );
  }
}
