import 'package:billkaro/app/modules/OwnerPanel/models/outlet_metrics.dart';
import 'package:billkaro/app/modules/OwnerPanel/owner_panel_controller.dart';
import 'package:billkaro/config/config.dart';

class OwnerKpiStrip extends StatelessWidget {
  const OwnerKpiStrip({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      final delta = s.salesDeltaPct;
      final up = delta >= 0;

      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final tiles = [
            _KpiTile(
              label: 'Today sales',
              value: formatOwnerMoney(s.todaySales),
              subtitle: up
                  ? '+${delta.toStringAsFixed(0)}% vs yesterday'
                  : '${delta.toStringAsFixed(0)}% vs yesterday',
              subtitleColor: up ? AppColor.success : AppColor.error,
              icon: Icons.payments_rounded,
              accent: AppColor.primary,
            ),
            _KpiTile(
              label: 'Today orders',
              value: '${s.todayOrders}',
              subtitle: 'Avg ${formatOwnerMoney(s.avgOrderValue)}',
              subtitleColor: AppColor.textSecondary,
              icon: Icons.receipt_long_rounded,
              accent: AppColor.secondaryPrimary,
            ),
            _KpiTile(
              label: 'Wallet balance',
              value: formatOwnerMoney(s.totalWalletBalance),
              subtitle: '${s.lowWalletOutlets} low / empty',
              subtitleColor:
                  s.lowWalletOutlets > 0 ? AppColor.error : AppColor.textSecondary,
              icon: Icons.account_balance_wallet_rounded,
              accent: AppColor.purple,
            ),
            _KpiTile(
              label: 'Inventory',
              value: formatOwnerMoney(s.totalStockValue),
              subtitle: '${s.lowStockOutlets} outlets low stock',
              subtitleColor:
                  s.lowStockOutlets > 0 ? AppColor.warning : AppColor.textSecondary,
              icon: Icons.inventory_2_rounded,
              accent: AppColor.teal,
            ),
            _KpiTile(
              label: 'Subscriptions',
              value: '${s.activeSubscriptions}',
              subtitle: '${s.expiringSubscriptions} expiring',
              subtitleColor: s.expiringSubscriptions > 0
                  ? AppColor.warning
                  : AppColor.textSecondary,
              icon: Icons.workspace_premium_rounded,
              accent: AppColor.secondaryPrimary,
            ),
            _KpiTile(
              label: '7-day sales',
              value: formatOwnerMoney(s.weekSales),
              subtitle: '${s.outletCount} outlets',
              subtitleColor: AppColor.textSecondary,
              icon: Icons.trending_up_rounded,
              accent: AppColor.info,
            ),
          ];

          if (wide) {
            return Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 3; i < 6; i++) ...[
                      if (i > 3) const SizedBox(width: 12),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                ),
              ],
            );
          }

          return Column(
            children: [
              for (var row = 0; row < 3; row++) ...[
                if (row > 0) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: tiles[row * 2]),
                    const SizedBox(width: 12),
                    Expanded(child: tiles[row * 2 + 1]),
                  ],
                ),
              ],
            ],
          );
        },
      );
    });
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.cardBorder.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColor.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
