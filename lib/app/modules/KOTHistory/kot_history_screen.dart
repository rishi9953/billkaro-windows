import 'dart:io' show Platform;

import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/KOTHistory/kot_history_controller.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class KotHistoryScreen extends StatefulWidget {
  const KotHistoryScreen({super.key});

  @override
  State<KotHistoryScreen> createState() => _KotHistoryScreenState();
}

class _KotHistoryScreenState extends State<KotHistoryScreen> {
  late final KotHistoryController c;
  final ScrollController _scrollController = ScrollController();

  bool _isWindowsDesktop() => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<KotHistoryController>()
        ? Get.find<KotHistoryController>()
        : Get.put(KotHistoryController());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      c.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (Get.isRegistered<KotHistoryController>()) {
      Get.delete<KotHistoryController>();
    }
    super.dispose();
  }

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

  Widget getIconFor(String value, {double size = 16}) {
    switch (value) {
      case 'Delivery':
        return Assets.delivery.image(width: size, height: size);
      case 'Dine In':
        return Assets.dineIn.image(width: size, height: size);
      case 'Swiggy':
        return Assets.svg.swiggy.svg(width: size, height: size);
      case 'Takeaway':
        return Assets.takeaway.image(width: size, height: size);
      case 'Zomato':
        return Assets.svg.zomato.svg(width: size, height: size);
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

  void _openKotReceipt(KotHistoryController c, OrderModel o) {
    Modular.to.pushNamed(
      HomeMainRoutes.kotReceipt,
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
  }

  Future<void> _onKotMenu(
    KotHistoryController c,
    OrderModel o,
    String value,
  ) async {
    if (value == 'view') {
      Modular.to.pushNamed(
        HomeMainRoutes.kotReceipt,
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
    } else if (value == 'print') {
      await c.reprintThermal(o);
    }
  }

  Widget _buildKotMenu(KotHistoryController c, OrderModel o, bool isWin) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey.shade600,
        size: isWin ? 22 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWin ? 8 : 12),
      ),
      onSelected: (v) => _onKotMenu(c, o, v),
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
    );
  }

  Widget _statusBadge(String status, {bool compact = false}) {
    final padH = compact ? 10.0 : 12.0;
    final padV = compact ? 5.0 : 6.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(compact ? 6 : 20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildChipsForOrder(OrderModel o, {required double iconSize}) {
    return [
      if (o.orderFrom.isNotEmpty)
        _buildOrderFromChip(
          iconWidget: getIconFor(o.orderFrom, size: iconSize),
          label: o.orderFrom,
          color: _getOrderFromColor(o.orderFrom),
        ),
      if (o.tableNumber != null && o.tableNumber!.isNotEmpty)
        _buildInfoChip(
          icon: Icons.table_restaurant,
          label: 'Table ${o.tableNumber}',
          color: AppColor.primary,
          iconSize: iconSize,
        ),
      if (o.customerName != null && o.customerName!.isNotEmpty)
        _buildInfoChip(
          icon: Icons.person_outline,
          label: o.customerName!,
          color: Colors.blue,
          iconSize: iconSize,
        ),
      if (o.phoneNumber != null && o.phoneNumber!.isNotEmpty)
        _buildInfoChip(
          icon: Icons.phone_outlined,
          label: o.phoneNumber!,
          color: Colors.green,
          iconSize: iconSize,
        ),
    ];
  }

  Widget _buildKotCard({
    required KotHistoryController c,
    required OrderModel o,
    required String dateStr,
    required String timeStr,
    required bool isWide,
    required bool isWin,
  }) {
    final radius = BorderRadius.circular(isWin ? 8 : 16);
    final chipIcon = isWin ? 14.0 : 16.0;
    final chips = _buildChipsForOrder(o, iconSize: chipIcon);

    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: radius,
      border: Border.all(color: Colors.grey.shade200, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isWin ? 0.04 : 0.06),
          blurRadius: isWin ? 4 : 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    if (isWide) {
      return Container(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: () => _openKotReceipt(c, o),
            hoverColor: AppColor.primary.withOpacity(0.06),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWin ? 20 : 24,
                vertical: isWin ? 14 : 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            size: isWin ? 22 : 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KOT #${o.billNumber}',
                                style: TextStyle(
                                  fontSize: isWin ? 15 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$dateStr • $timeStr',
                                style: TextStyle(
                                  fontSize: isWin ? 11 : 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: chips.isEmpty
                          ? const SizedBox.shrink()
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.start,
                              children: chips,
                            ),
                    ),
                  ),
                  _statusBadge(o.status, compact: true),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 108,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: isWin ? 10 : 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(o.totalAmount),
                          style: TextStyle(
                            fontSize: isWin ? 17 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildKotMenu(c, o, isWin),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: () => _openKotReceipt(c, o),
          hoverColor: isWin ? AppColor.primary.withOpacity(0.06) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    _statusBadge(o.status),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                if (o.orderFrom.isNotEmpty ||
                    o.tableNumber != null ||
                    o.customerName != null ||
                    o.phoneNumber != null)
                  Wrap(spacing: 16, runSpacing: 12, children: chips),
                const SizedBox(height: 16),
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
                    _buildKotMenu(c, o, isWin),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(bool isWin) {
    return Obx(() {
      if (c.isLoadingMore.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: isWin ? 28 : 32,
              height: isWin ? 28 : 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColor.primary,
              ),
            ),
          ),
        );
      }
      if (!c.hasMoreData.value && c.orders.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'No more KOTs',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
      if (c.hasMoreData.value && c.orders.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    final isWin = _isWindowsDesktop();

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'KOT History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: c.load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxOuter = constraints.maxWidth;
            final maxW = maxOuter > 1100
                ? 1100.0
                : (maxOuter > 720 ? 900.0 : maxOuter);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: LayoutBuilder(
                  builder: (context, inner) {
                    final innerW = inner.maxWidth;
                    final isWide = innerW >= 720;
                    final hPad = isWin ? 24.0 : 16.0;
                    final vPad = isWin ? 12.0 : 16.0;
                    final searchRadius = isWin ? 8.0 : 16.0;

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(searchRadius),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColor.primary,
                                ),
                                hintText:
                                    'Search by bill, table, customer, phone, source',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    searchRadius,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isWin ? 16 : 20,
                                  vertical: isWin ? 14 : 16,
                                ),
                              ),
                              onChanged: c.onSearchChanged,
                            ),
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
                            final list = c.orders;
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
                                        color: Colors.grey.shade700,
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
                              controller: _scrollController,
                              physics: isWin
                                  ? const ClampingScrollPhysics()
                                  : const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
                              itemCount: list.length + 1,
                              separatorBuilder: (context, index) {
                                if (index >= list.length) {
                                  return const SizedBox.shrink();
                                }
                                return SizedBox(height: isWin ? 10 : 12);
                              },
                              itemBuilder: (context, i) {
                                if (i == list.length) {
                                  return _buildPaginationFooter(isWin);
                                }
                                final o = list[i];
                                final dateStr = formatDate(
                                  o.createdAt,
                                  format: 'dd MMM yyyy',
                                );
                                final timeStr = formatTime(o.createdAt);

                                return _buildKotCard(
                                  c: c,
                                  o: o,
                                  dateStr: dateStr,
                                  timeStr: timeStr,
                                  isWide: isWide,
                                  isWin: isWin,
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderFromChip({
    required Widget iconWidget,
    required String label,
    required Color color,
    double fontSize = 12,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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
                fontSize: fontSize,
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
    double iconSize = 14,
    double fontSize = 12,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
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
