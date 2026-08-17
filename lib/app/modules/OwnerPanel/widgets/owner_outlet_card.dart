import 'package:billkaro/app/modules/OwnerPanel/models/outlet_metrics.dart';
import 'package:billkaro/app/modules/OwnerPanel/owner_panel_controller.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:fl_chart/fl_chart.dart';

class OwnerOutletCard extends StatelessWidget {
  const OwnerOutletCard({
    super.key,
    required this.metrics,
    required this.controller,
    required this.rank,
    required this.maxSales,
    required this.isExpanded,
    required this.isActive,
  });

  final OutletMetrics metrics;
  final OwnerPanelController controller;
  final int rank;
  final double maxSales;
  final bool isExpanded;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final range = controller.selectedRange.value;
    final sales = metrics.salesFor(range);
    final orders = metrics.ordersFor(range);
    final share = maxSales <= 0 ? 0.0 : (sales / maxSales).clamp(0.0, 1.0);
    final delta = metrics.salesDeltaPct();
    final up = delta >= 0;
    final outlet = metrics.outlet;
    final color = AppColor.chartPalette[(rank - 1) % AppColor.chartPalette.length];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => controller.toggleExpanded(outlet.id),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppColor.primary.withOpacity(0.4)
                  : AppColor.cardBorder.withOpacity(0.8),
              width: isActive ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RankBadge(rank: rank, color: color),
                    const SizedBox(width: 10),
                    _Logo(logoUrl: outlet.logo, name: metrics.name, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  metrics.name.capitalizeFirst ?? metrics.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _typeLabel(outlet),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                formatOwnerMoney(sales),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColor.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (up ? AppColor.success : AppColor.error)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${up ? '+' : ''}${delta.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: up ? AppColor.success : AppColor.error,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$orders orders',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _StatusPill(
                                label: formatOwnerMoney(metrics.wallet.balance),
                                color: metrics.wallet.isLow
                                    ? AppColor.error
                                    : AppColor.purple,
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              _StatusPill(
                                label: metrics.inventory.hasLowStock
                                    ? '${metrics.inventory.lowStockCount} low stock'
                                    : 'Stock OK',
                                color: metrics.inventory.hasLowStock
                                    ? AppColor.warning
                                    : AppColor.success,
                                icon: Icons.inventory_2_outlined,
                              ),
                              _StatusPill(
                                label: metrics.subscription.status,
                                color: switch (metrics.subscription.status) {
                                  'Active' => AppColor.success,
                                  'Expiring' => AppColor.warning,
                                  'Expired' => AppColor.error,
                                  _ => Colors.grey,
                                },
                                icon: Icons.workspace_premium_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: share,
                              minHeight: 6,
                              backgroundColor: color.withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 56,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            lineTouchData: const LineTouchData(enabled: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (var i = 0;
                                      i < metrics.weekSeries.length;
                                      i++)
                                    FlSpot(
                                      i.toDouble(),
                                      metrics.weekSeries[i],
                                    ),
                                ],
                                isCurved: true,
                                color: color,
                                barWidth: 2.2,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: color.withOpacity(0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MiniStatRow(
                        items: [
                          _MiniStat(
                            'Today',
                            formatOwnerMoney(metrics.todaySales),
                          ),
                          _MiniStat(
                            '7 days',
                            formatOwnerMoney(metrics.weekSales),
                          ),
                          _MiniStat(
                            'Wallet',
                            formatOwnerMoney(metrics.wallet.balance),
                          ),
                          _MiniStat(
                            'Stock',
                            formatOwnerMoney(metrics.inventory.totalStockValue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MiniStatRow(
                        items: [
                          _MiniStat(
                            'Sub',
                            metrics.subscription.status,
                          ),
                          _MiniStat(
                            'Low items',
                            '${metrics.inventory.lowStockCount}',
                          ),
                          _MiniStat(
                            'Pending PO',
                            '${metrics.inventory.pendingPurchaseOrders}',
                          ),
                          _MiniStat(
                            'AOV',
                            formatOwnerMoney(metrics.avgOrderValue),
                          ),
                        ],
                      ),
                      if (metrics.recentOrders.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent bills',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...metrics.recentOrders.take(4).map((o) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Bill #${o.billNumber}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatOwnerMoney(o.totalAmount),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      if (metrics.paymentBreakdown.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Today’s payments',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: metrics.paymentBreakdown.entries.map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                '${e.key.toUpperCase()} · ${formatOwnerMoney(e.value)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _DetailGrid(controller: controller, outlet: outlet),
                      if (!isActive) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => controller.switchToOutlet(outlet),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            label: const Text('Switch to this outlet'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColor.primary,
                              side: BorderSide(
                                color: AppColor.primary.withOpacity(0.4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  String _typeLabel(OutletData outlet) {
    final parts = <String>[
      if ((outlet.businessType ?? '').trim().isNotEmpty)
        outlet.businessType!.trim(),
      if ((outlet.businessCategory ?? '').trim().isNotEmpty)
        outlet.businessCategory!.trim(),
    ];
    return parts.isEmpty ? 'Outlet' : parts.join(' · ');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.color});

  final int rank;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({
    required this.logoUrl,
    required this.name,
    required this.color,
  });

  final String? logoUrl;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasLogo = (logoUrl ?? '').trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        color: color.withOpacity(0.12),
        child: hasLogo
            ? AppCachedNetworkImage(
                imageUrl: resolvedMediaUrl(logoUrl!.trim()),
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    final t = name.trim();
    return Center(
      child: Text(
        t.isEmpty ? 'O' : t.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({required this.items});

  final List<_MiniStat> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.controller, required this.outlet});

  final OwnerPanelController controller;
  final OutletData outlet;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Phone', controller.valueOrDash(outlet.phoneNumber)),
      MapEntry('Address', controller.valueOrDash(outlet.outletAddress)),
      MapEntry('UPI', controller.valueOrDash(outlet.upiId)),
      MapEntry('GSTIN', controller.valueOrDash(outlet.gstinNumber)),
      MapEntry('FSSAI', controller.valueOrDash(outlet.fssaiNumber)),
      MapEntry('Tax', controller.valueOrDash(outlet.taxSlab)),
      MapEntry('Seating', controller.valueOrDash(outlet.seatingCapacity)),
      MapEntry('Plan', controller.activePlanLabel(outlet)),
    ];

    return Column(
      children: rows
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
