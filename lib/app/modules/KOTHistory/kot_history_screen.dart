import 'package:billkaro/app/modules/KOTHistory/kot_history_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter/material.dart';

class KotHistoryScreen extends StatelessWidget {
  const KotHistoryScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return AppColor.lightgreen;
      case 'pending':
        return AppColor.secondaryPrimary;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Widget getIconFor(String value) {
    switch (value) {
      case 'Delivery':
        return Assets.delivery.image(width: 16, height: 16);
      case 'Dine In':
        return Assets.dineIn.image(width: 16, height: 16);
      case 'Swiggy':
        return Assets.svg.swiggy.svg(width: 16, height: 16);
      case 'Takeaway':
        return Assets.takeaway.image(width: 16, height: 16);
      case 'Zomato':
        return Assets.svg.zomato.svg(width: 16, height: 16);
      default:
        return const SizedBox();
    }
  }

  Color _getOrderFromColor(String orderFrom) {
    final lower = orderFrom.toLowerCase();
    if (lower.contains('dine in') || lower.contains('dinein')) {
      return AppColor.primary;
    } else if (lower.contains('takeaway') || lower.contains('take away')) {
      return AppColor.secondaryPrimary;
    } else if (lower.contains('delivery')) {
      return Colors.orange;
    } else if (lower.contains('swiggy') || lower.contains('zomato')) {
      return Colors.purple;
    } else if (lower.contains('online')) {
      return Colors.blue;
    } else {
      return AppColor.secondaryPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(KotHistoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('KOT History'),
        actions: [
          IconButton(
            onPressed: c.load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColor.primary),
                hintText: 'Search by bill/table/customer/phone/source',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (v) => c.search.value = v,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColor.primary,
                  ),
                );
              }
              final list = c.filtered;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No KOTs found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.search.value.isEmpty
                            ? 'No orders available'
                            : 'Try a different search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final o = list[i];
                  final dateStr = formatDate(o.createdAt, format: 'dd MMM yyyy');
                  final timeStr = formatTime(o.createdAt);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Get.toNamed(
                            AppRoute.KOTInvoice,
                            arguments: {
                              'invoice': c.toKOTRequest(o),
                              'orderFrom': o.orderFrom,
                              'tableNumber': o.tableNumber ?? '',
                              'orderId': o.id,
                              'orderStatus': o.status,
                              'isEdit': false,
                              'specialInstructions': '',
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row: KOT Number and Status
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColor.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long,
                                            color: AppColor.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'KOT #${o.billNumber}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColor.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$dateStr • $timeStr',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(o.status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(o.status).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      o.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(o.status),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Divider
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade200,
                              ),
                              const SizedBox(height: 16),
                              // Order Details
                              if (o.orderFrom.isNotEmpty ||
                                  o.tableNumber != null ||
                                  o.customerName != null ||
                                  o.phoneNumber != null)
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  children: [
                                    if (o.orderFrom.isNotEmpty)
                                      _buildOrderFromChip(
                                        iconWidget: getIconFor(o.orderFrom),
                                        label: o.orderFrom,
                                        color: _getOrderFromColor(o.orderFrom),
                                      ),
                                    if (o.tableNumber != null && o.tableNumber!.isNotEmpty)
                                      _buildInfoChip(
                                        icon: Icons.table_restaurant,
                                        label: 'Table ${o.tableNumber}',
                                        color: AppColor.primary,
                                      ),
                                    if (o.customerName != null && o.customerName!.isNotEmpty)
                                      _buildInfoChip(
                                        icon: Icons.person_outline,
                                        label: o.customerName!,
                                        color: Colors.blue,
                                      ),
                                    if (o.phoneNumber != null && o.phoneNumber!.isNotEmpty)
                                      _buildInfoChip(
                                        icon: Icons.phone_outlined,
                                        label: o.phoneNumber!,
                                        color: Colors.green,
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // Footer: Total Amount and Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Amount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(o.totalAmount),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey.shade600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (v) async {
                                      if (v == 'view') {
                                        Get.toNamed(
                                          AppRoute.KOTInvoice,
                                          arguments: {
                                            'invoice': c.toKOTRequest(o),
                                            'orderFrom': o.orderFrom,
                                            'tableNumber': o.tableNumber ?? '',
                                            'orderId': o.id,
                                            'orderStatus': o.status,
                                            'isEdit': false,
                                            'specialInstructions': '',
                                          },
                                        );
                                      } else if (v == 'print') {
                                        await c.reprintThermal(o);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.visibility_outlined,
                                              size: 20,
                                              color: AppColor.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('View KOT'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'print',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.print_outlined,
                                              size: 20,
                                              color: AppColor.secondaryPrimary,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Reprint (Thermal)'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFromChip({
    required Widget iconWidget,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


