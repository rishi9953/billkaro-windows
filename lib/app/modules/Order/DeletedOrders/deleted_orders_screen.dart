import 'package:billkaro/app/modules/Order/DeletedOrders/deleted_orders_controller.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:billkaro/utils/staff_access.dart';

class DeletedOrdersScreen extends StatefulWidget {
  const DeletedOrdersScreen({super.key});

  @override
  State<DeletedOrdersScreen> createState() => _DeletedOrdersScreenState();
}

class _DeletedOrdersScreenState extends State<DeletedOrdersScreen> {
  late final DeletedOrdersController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<DeletedOrdersController>()
        ? Get.find<DeletedOrdersController>()
        : Get.put(DeletedOrdersController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getOrderList(forceApiRefresh: true);
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<DeletedOrdersController>()) {
      Get.delete<DeletedOrdersController>();
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
          loc.deleted_orders_title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
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
    );
  }

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
              if (index >= controller.allOrders.length - 1) {
                return const SizedBox.shrink();
              }
              return const SizedBox(height: 14);
            },
            itemBuilder: (context, index) {
              if (index == controller.allOrders.length) {
                return Obx(
                  () => controller.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink(),
                );
              }
              final order = controller.allOrders[index];
              return _DeletedOrderCard(
                order: order,
                onRestore: () => _confirmRestore(order, loc),
              );
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
          Icon(Icons.delete_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            loc.no_deleted_orders,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.deleted_orders_empty_hint,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(OrderModel order, AppLocalizations loc) {
    if (!StaffAccess.ensure(StaffAccess.canUpdateSales)) return;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.restore_order,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          loc.restore_order_confirm_message,
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
              controller.restoreOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.restore),
          ),
        ],
      ),
    );
  }
}

class _DeletedOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onRestore;

  const _DeletedOrderCard({
    required this.order,
    required this.onRestore,
  });

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loc.deleted_badge,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
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
            Row(
              children: [
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
            if (order.billNumber.trim().isNotEmpty)
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
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
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
                        order.items.take(2).map((e) => e.itemName).join(', '),
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
                if (StaffAccess.canUpdateSales)
                  Tooltip(
                    message: loc.restore_order,
                    child: IconButton(
                      onPressed: onRestore,
                      icon: const Icon(Icons.restore_rounded, size: 20),
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
    );
  }
}
