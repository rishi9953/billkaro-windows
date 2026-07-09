import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerDetails/customer_details_controller.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CustomerDetailsScreen extends StatelessWidget {
  CustomerDetailsScreen({super.key});
  final controller = Get.put(CustomerDetailsController());

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        elevation: 0,
        title: Text(loc.customer_details),
        actions: [
          IconButton(
            icon: Assets.svg.whatsapp.svg(width: 24, height: 24),
            onPressed: () => openWhatsApp(controller.phoneNumber.value),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Modular.to.pushNamed(
                HomeMainRoutes.addRegularCustomer,
                arguments: {
                  'isEdit': true,
                  'customerData': controller.customer,
                },
              );
            },
          ),
          // Refresh button
          IconButton(
            onPressed: () => controller.loadCustomerDetails(),
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.loadError.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.loadError.value, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadCustomerDetails(),
                    child: Text(loc.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final customerName = controller.customerName.value;
        final phoneNumber = controller.phoneNumber.value;
        final loyaltyDiscount = controller.loyaltyDiscount.value;
        final loyaltyDiscountType = controller.loyaltyDiscountType.value;
        final customerInitial = customerName.trim().isEmpty
            ? '?'
            : customerName.trim()[0].toUpperCase();
        final totalVisits = controller.totalVisits.value;
        final orderValue = controller.orderValue.value;
        final avgOrder = controller.avgOrder.value;
        final totalDiscount = controller.totalDiscount.value;
        final lastOrder = controller.lastOrder;
        final orders = controller.orders;
        final ordersLoading = controller.ordersLoading.value;
        final ordersRangeLabel = controller.ordersRangeLabel;
        final currentPage = controller.currentPage.value;
        final totalPages = controller.totalPages.value;
        final ordersLoadingPages = controller.ordersLoading.value;
        final visiblePages = controller.visiblePageNumbers;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(
                  loc: loc,
                  customerInitial: customerInitial,
                  customerName: customerName,
                  phoneNumber: phoneNumber,
                  loyaltyDiscount: loyaltyDiscount,
                  loyaltyDiscountType: loyaltyDiscountType,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildStatsGrid(
                      loc: loc,
                      isWide: constraints.maxWidth > 700,
                      totalVisits: totalVisits,
                      orderValue: orderValue,
                      avgOrder: avgOrder,
                      totalDiscount: totalDiscount,
                    );
                  },
                ),
                if (lastOrder != null) ...[
                  const SizedBox(height: 16),
                  _buildLastOrderBanner(loc, lastOrder),
                ],
                const SizedBox(height: 20),
                _buildOrderHistoryHeader(loc, ordersRangeLabel),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildOrderHistory(
                          loc: loc,
                          orders: orders,
                          ordersLoading: ordersLoading,
                          currentPage: currentPage,
                        ),
                        const SizedBox(height: 12),
                        _buildPagination(
                          totalPages: totalPages,
                          currentPage: currentPage,
                          visiblePages: visiblePages,
                          ordersLoading: ordersLoadingPages,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileCard({
    required AppLocalizations loc,
    required String customerInitial,
    required String customerName,
    required String phoneNumber,
    required double loyaltyDiscount,
    required String loyaltyDiscountType,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColor.primary.withOpacity(0.12),
            child: Text(
              customerInitial,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColor.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColor.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  loyaltyDiscountType == 'amount'
                      ? '₹${loyaltyDiscount.toStringAsFixed(0)}'
                      : '${loyaltyDiscount.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.loyalty,
                  style: TextStyle(fontSize: 12, color: AppColor.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required AppLocalizations loc,
    required bool isWide,
    required int totalVisits,
    required double orderValue,
    required double avgOrder,
    required double totalDiscount,
  }) {
    final children = [
      _buildStatCard(
        icon: Icons.receipt_long_outlined,
        label: loc.total_visits,
        value: '$totalVisits',
        color: Colors.blue,
      ),
      _buildStatCard(
        icon: Icons.payments_outlined,
        label: loc.customer_order_value,
        value: '₹${orderValue.toStringAsFixed(0)}',
        color: Colors.green,
      ),
      _buildStatCard(
        icon: Icons.trending_up,
        label: loc.avg_order,
        value: '₹${avgOrder.toStringAsFixed(0)}',
        color: Colors.orange,
      ),
      _buildStatCard(
        icon: Icons.discount_outlined,
        label: loc.customer_total_discount,
        value: '₹${totalDiscount.toStringAsFixed(0)}',
        color: Colors.purple,
      ),
    ];

    if (isWide) {
      return Row(
        children: children
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 10),
            Expanded(child: children[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: children[2]),
            const SizedBox(width: 10),
            Expanded(child: children[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppColor.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastOrderBanner(AppLocalizations loc, CustomerLastOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primary.withOpacity(0.9), AppColor.primary],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.latest_order,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  loc.bill_amount_summary(
                    order.billNumber,
                    order.totalAmount.toStringAsFixed(2),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            controller.formatOrderDate(order.orderDate).split(' • ').first,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryHeader(
    AppLocalizations loc,
    String ordersRangeLabel,
  ) {
    return Row(
      children: [
        Text(
          loc.order_history,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          ordersRangeLabel,
          style: TextStyle(fontSize: 13, color: AppColor.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildOrderHistory({
    required AppLocalizations loc,
    required List<CustomerLastOrder> orders,
    required bool ordersLoading,
    required int currentPage,
  }) {
    if (ordersLoading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 42,
              color: AppColor.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              loc.no_orders_yet_for_customer,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColor.grey.shade200),
        itemBuilder: (context, index) {
          final rowNumber =
              ((currentPage - 1) * CustomerDetailsController.pageLimit) +
              index +
              1;
          return _buildOrderTile(loc, orders[index], rowNumber);
        },
      ),
    );
  }

  Widget _buildOrderTile(
    AppLocalizations loc,
    CustomerLastOrder order,
    int rowNumber,
  ) {
    final isClosed = order.status.toLowerCase() == 'closed';
    final discountSuffix = order.discount > 0
        ? loc.order_discount_amount(order.discount.toStringAsFixed(0))
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rowNumber',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.bill_number_short(order.billNumber),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.formatOrderDate(order.orderDate),
                  style: TextStyle(fontSize: 13, color: AppColor.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.paymentType.toUpperCase()}$discountSuffix',
                  style: TextStyle(fontSize: 13, color: AppColor.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isClosed
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isClosed ? loc.status_closed : loc.status_pending,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isClosed
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination({
    required int totalPages,
    required int currentPage,
    required List<int> visiblePages,
    required bool ordersLoading,
  }) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pageWidgets = <Widget>[];
    for (var i = 0; i < visiblePages.length; i++) {
      if (i > 0 && visiblePages[i] > visiblePages[i - 1] + 1) {
        pageWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...'),
          ),
        );
      }
      pageWidgets.add(
        _pageNumber(
          page: visiblePages[i],
          currentPage: currentPage,
          ordersLoading: ordersLoading,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageArrow(
            icon: Icons.chevron_left,
            enabled: currentPage > 1,
            ordersLoading: ordersLoading,
            onTap: () => controller.goToPage(currentPage - 1),
          ),
          const SizedBox(width: 6),
          ...pageWidgets,
          const SizedBox(width: 6),
          _pageArrow(
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages,
            ordersLoading: ordersLoading,
            onTap: () => controller.goToPage(currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _pageNumber({
    required int page,
    required int currentPage,
    required bool ordersLoading,
  }) {
    final isActive = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: ordersLoading ? null : () => controller.goToPage(page),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36),
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColor.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColor.primary : AppColor.grey.shade300,
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageArrow({
    required IconData icon,
    required bool enabled,
    required bool ordersLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled && !ordersLoading ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.grey.shade300),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? Colors.black87 : AppColor.grey.shade400,
        ),
      ),
    );
  }
}
