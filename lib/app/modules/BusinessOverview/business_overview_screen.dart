import 'package:billkaro/app/modules/BusinessOverview/business_overview_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class BusinessOverviewScreen extends StatelessWidget {
  const BusinessOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BusinessOverviewController controller = Get.put(
      BusinessOverviewController(),
    );
    var loc = AppLocalizations.of(Get.context!)!;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.businessOverview,
          style: TextStyle(
            color: AppColor.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColor.primary,
        onRefresh: () async {
          // await controller.refreshData();
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSalesCard(controller, loc)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildTrendsCard(controller, loc)),
                      ],
                    )
                  else ...[
                    _buildSalesCard(controller, loc),
                    const SizedBox(height: 16),
                    _buildTrendsCard(controller, loc),
                  ],
                  const SizedBox(height: 20),
                  _buildMostSellingCard(controller, loc),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesCard(
    BusinessOverviewController controller,
    AppLocalizations loc,
  ) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.sales,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    label: loc.todaysSales,
                    value:
                        '₹${controller.todayTotalSales.value.toStringAsFixed(0)}',
                    subtitle:
                        '₹${controller.yesterdaySales.value.toStringAsFixed(0)} (${loc.yesterday})',
                    color: AppColor.primary,
                    alignment: CrossAxisAlignment.start,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricItem(
                    label: loc.todaysOrders,
                    value: '${controller.todayTotalOrders.value}',
                    subtitle:
                        '${controller.yesterdayOrders.value} (${loc.yesterday})',
                    color: AppColor.secondaryPrimary,
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSimpleButton(
            text: loc.view_Order_Reports,
            icon: Icons.arrow_forward_ios,
            onTap: () => Modular.to.pushNamed(HomeMainRoutes.orderReport),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard(
    BusinessOverviewController controller,
    AppLocalizations loc,
  ) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.secondaryPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColor.secondaryPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.trends,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildTrendItem(
                    title: loc.lAST_MONTH,
                    avgOrder: controller.lastMonthAvgDailyOrder.value
                        .toStringAsFixed(1),
                    avgSale:
                        '₹${controller.lastMonthAvgDailySale.value.toStringAsFixed(0)}',
                    loc: loc,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTrendItem(
                    title: loc.tHIS_MONTH,
                    avgOrder: controller.thisMonthAvgDailyOrder.value
                        .toStringAsFixed(1),
                    avgSale:
                        '₹${controller.thisMonthAvgDailySale.value.toStringAsFixed(0)}',
                    loc: loc,
                    isHighlighted: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostSellingCard(
    BusinessOverviewController controller,
    AppLocalizations loc,
  ) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star_outline,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.most_Selling_Items,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildTabChip(
                    text: loc.lAST_7_DAYS,
                    isSelected: controller.selectedTab.value == 0,
                    onTap: () => controller.selectTab(0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabChip(
                    text: loc.lAST_30_DAYS,
                    isSelected: controller.selectedTab.value == 1,
                    onTap: () => controller.selectTab(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // _buildEmptyState(loc),
          Obx(() {
            return _buildMostSellingList(controller, loc);
          }),

          const SizedBox(height: 16),
          _buildSimpleButton(
            text: loc.view_Item_Reports,
            icon: Icons.arrow_forward_ios,
            onTap: () => Modular.to.pushNamed(HomeMainRoutes.itemsReport),
          ),
        ],
      ),
    );
  }

  Widget _buildMostSellingList(
    BusinessOverviewController controller,
    AppLocalizations loc,
  ) {
    if (controller.mostSellingItems.isEmpty) {
      return _buildEmptyState(loc);
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: controller.mostSellingItems.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () => Modular.to.pushNamed(HomeMainRoutes.itemsReport),
          child: _sellingCard(controller.mostSellingItems[index], index + 1),
        ),
      ),
    );
  }

  Widget _sellingCard(Map<String, dynamic> item, int rank) {
    //List<Map<String, dynamic>> item, int rank) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 14),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "QTY ${item["qty"]}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹ ${item["price"]}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  item["name"],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.north_east,
                    size: 20,
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ),

          /// Background Rank Number
          Positioned(
            left: -5,
            top: 40,
            child: Opacity(
              opacity: 0.15,
              child: Text(
                "$rank",
                style: TextStyle(
                  fontSize: 70,
                  color: Colors.blue.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildTrendItem({
    required String title,
    required String avgOrder,
    required String avgSale,
    required AppLocalizations loc,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColor.secondaryPrimary.withOpacity(0.08)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? AppColor.secondaryPrimary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isHighlighted
                  ? AppColor.secondaryPrimary
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendMetric(
            icon: Icons.shopping_cart_outlined,
            value: avgOrder,
            label: loc.avg_daily_order,
          ),
          const SizedBox(height: 12),
          _buildTrendMetric(
            icon: Icons.account_balance_wallet_outlined,
            value: avgSale,
            label: loc.avg_daily_sale,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColor.primary.withOpacity(0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColor.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColor.primary : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColor.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.primary),
            boxShadow: [
              BoxShadow(
                color: AppColor.primary.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Column(
      children: [
        Lottie.asset('assets/lottie/Emptybox.json', height: 100),
        const SizedBox(height: 16),
        Text(
          loc.no_Data_Available,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loc.you_havent_added_any_orders_yet_Add_an_order_to_see_most_selling_items,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 16),
        _buildSimpleButton(
          text: loc.view_Item_Reports,
          icon: Icons.arrow_forward_ios,
          onTap: () => Get.toNamed(AppRoute.itemReports),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
