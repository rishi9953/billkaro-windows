import 'package:billkaro/app/modules/OwnerPanel/models/outlet_metrics.dart';
import 'package:billkaro/app/modules/OwnerPanel/owner_panel_controller.dart';
import 'package:billkaro/app/modules/OwnerPanel/widgets/owner_charts.dart';
import 'package:billkaro/app/modules/OwnerPanel/widgets/owner_kpi_strip.dart';
import 'package:billkaro/app/modules/OwnerPanel/widgets/owner_outlet_card.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

class OwnerOverviewTab extends StatelessWidget {
  const OwnerOverviewTab({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final todayLabel = DateFormat('EEEE, d MMM').format(DateTime.now());

    return Obx(() {
      final outletCount = controller.summary.value.outletCount;
      return _TabScroll(
        onRefresh: controller.refreshDashboard,
        children: [
          _HeroHeader(
            title: loc.owner_panel_heading,
            dateLabel: todayLabel,
            outletCount: outletCount,
          ),
          const SizedBox(height: 14),
          OwnerKpiStrip(controller: controller),
          const SizedBox(height: 14),
          OwnerSalesTrendChart(controller: controller),
          const SizedBox(height: 14),
          OwnerOutletComparisonChart(controller: controller),
        ],
      );
    });
  }
}

class OwnerInventoryTab extends StatelessWidget {
  const OwnerInventoryTab({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      final inventory = controller.filteredMetrics;
      final lowStock = controller.aggregatedLowStock;

      return _TabScroll(
        onRefresh: controller.refreshDashboard,
        children: [
          _SectionCard(
            icon: Icons.inventory_2_outlined,
            accent: AppColor.teal,
            title: 'Inventory health',
            subtitle:
                '${s.lowStockOutlets} outlets need attention · stock value ${formatOwnerMoney(s.totalStockValue)}',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: 'Stock value',
                        value: formatOwnerMoney(s.totalStockValue),
                      ),
                    ),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Low-stock outlets',
                        value: '${s.lowStockOutlets}',
                        danger: s.lowStockOutlets > 0,
                      ),
                    ),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Pending POs',
                        value:
                            '${inventory.fold<int>(0, (a, m) => a + m.inventory.pendingPurchaseOrders)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (lowStock.isEmpty)
                  _EmptyHint('No low-stock alerts for the current filter.')
                else ...[
                  const _SectionLabel('Low stock items'),
                  const SizedBox(height: 8),
                  ...lowStock.map(
                    (item) => _ListRow(
                      title: item.name,
                      trailing:
                          '${item.currentStock.toStringAsFixed(1)} / ${item.minStock.toStringAsFixed(1)} ${item.unit}',
                      trailingColor: AppColor.warning,
                    ),
                  ),
                ],
                if (inventory.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _SectionLabel('Per outlet'),
                  const SizedBox(height: 8),
                  ...inventory.map(
                    (m) => _ListRow(
                      title: m.name,
                      trailing:
                          '${m.inventory.lowStockCount} low · ${formatOwnerMoney(m.inventory.totalStockValue)}',
                      trailingColor: m.inventory.hasLowStock
                          ? AppColor.warning
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class OwnerWalletTab extends StatelessWidget {
  const OwnerWalletTab({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      final walletTx = controller.recentWalletTransactions;
      final outlets = controller.filteredMetrics;

      return _TabScroll(
        onRefresh: controller.refreshDashboard,
        children: [
          _SectionCard(
            icon: Icons.account_balance_wallet_outlined,
            accent: AppColor.purple,
            title: 'Wallet overview',
            subtitle:
                'Total ${formatOwnerMoney(s.totalWalletBalance)} · ${s.lowWalletOutlets} outlets low/empty',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: 'Combined balance',
                        value: formatOwnerMoney(s.totalWalletBalance),
                      ),
                    ),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Low wallets',
                        value: '${s.lowWalletOutlets}',
                        danger: s.lowWalletOutlets > 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionLabel('Outlet balances'),
                const SizedBox(height: 8),
                if (outlets.isEmpty)
                  const _EmptyHint('No outlets in current filter.')
                else
                  ...outlets.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (m.wallet.isLow
                                      ? AppColor.error
                                      : AppColor.success)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatOwnerMoney(m.wallet.balance),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: m.wallet.isLow
                                    ? AppColor.error
                                    : AppColor.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                if (walletTx.isNotEmpty) ...[
                  const Divider(height: 24),
                  const _SectionLabel('Latest wallet transactions'),
                  const SizedBox(height: 8),
                  ...walletTx.map((row) {
                    final tx = row.value;
                    final credit = tx.isCredit;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            credit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
                            color: credit ? AppColor.success : AppColor.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description.isEmpty
                                      ? (credit ? 'Credit' : 'Debit')
                                      : tx.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${row.key.name} · ${DateFormat('d MMM, h:mm a').format(tx.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${credit ? '+' : '-'}${formatOwnerMoney(tx.amount)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color:
                                  credit ? AppColor.success : AppColor.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class OwnerSubscriptionsTab extends StatelessWidget {
  const OwnerSubscriptionsTab({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      final subs = controller.filteredMetrics;

      return _TabScroll(
        onRefresh: controller.refreshDashboard,
        children: [
          _SectionCard(
            icon: Icons.workspace_premium_outlined,
            accent: AppColor.secondaryPrimary,
            title: 'Subscriptions',
            subtitle:
                '${s.activeSubscriptions} active · ${s.expiringSubscriptions} expiring soon',
            child: Column(
              children: subs.isEmpty
                  ? [const _EmptyHint('No outlets in current filter.')]
                  : subs.map((m) {
                      final sub = m.subscription;
                      final color = switch (sub.status) {
                        'Active' => AppColor.success,
                        'Expiring' => AppColor.warning,
                        'Expired' => AppColor.error,
                        _ => Colors.grey,
                      };
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sub.planLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (sub.endDate != null)
                                    Text(
                                      'Ends ${DateFormat('d MMM yyyy').format(sub.endDate!)}'
                                      '${sub.daysRemaining != null && sub.isActive ? ' · ${sub.daysRemaining}d left' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  if ((sub.paymentId ?? '').isNotEmpty)
                                    Text(
                                      'Payment: ${sub.paymentId}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                sub.status,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),
        ],
      );
    });
  }
}

class OwnerTransactionsTab extends StatelessWidget {
  const OwnerTransactionsTab({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final salesTx = controller.recentSalesTransactions;

      return _TabScroll(
        onRefresh: controller.refreshDashboard,
        children: [
          _SectionCard(
            icon: Icons.receipt_long_outlined,
            accent: AppColor.primary,
            title: 'Recent sales transactions',
            subtitle: 'Latest closed bills across filtered outlets',
            child: salesTx.isEmpty
                ? const _EmptyHint('No recent closed orders found.')
                : Column(
                    children: salesTx.map((tx) {
                      final order = tx.order;
                      final when = DateTime.tryParse(order.createdAt);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColor.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.receipt_rounded,
                                size: 18,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bill #${order.billNumber}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${tx.outletName} · ${order.paymentReceivedIn ?? order.orderFrom}'
                                    '${when != null ? ' · ${DateFormat('d MMM, h:mm a').format(when)}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatOwnerMoney(order.totalAmount),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColor.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      );
    });
  }
}

class OwnerOutletsTab extends StatelessWidget {
  const OwnerOutletsTab({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Obx(() {
      final ranked = controller.rankedBySelectedRange;
      final maxSales = ranked.isEmpty
          ? 1.0
          : ranked.first.salesFor(controller.selectedRange.value);
      final expanded = controller.expandedOutletIds.toSet();
      final activeId = controller.activeOutletId.value;

      return _TabScroll(
        onRefresh: controller.refreshDashboard,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Outlet performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              Text(
                '${ranked.length} listed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a card for wallet, stock, bills & profile',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          if (ranked.isEmpty)
            _EmptyHint(loc.owner_panel_no_results)
          else
            ...List.generate(ranked.length, (index) {
              final m = ranked[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == ranked.length - 1 ? 0 : 12,
                ),
                child: OwnerOutletCard(
                  metrics: m,
                  controller: controller,
                  rank: index + 1,
                  maxSales: maxSales <= 0 ? 1 : maxSales,
                  isExpanded: expanded.contains(m.id),
                  isActive: m.id == activeId,
                ),
              );
            }),
        ],
      );
    });
  }
}

class _TabScroll extends StatelessWidget {
  const _TabScroll({required this.children, required this.onRefresh});

  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: children,
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.dateLabel,
    required this.outletCount,
  });

  final String title;
  final String dateLabel;
  final int outletCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.primary,
            Color.lerp(AppColor.primary, const Color(0xFF0B5A8C), 0.55)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Live sales, inventory, wallet & subscriptions',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '$outletCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'outlets',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: danger ? AppColor.error : AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.trailing,
    this.trailingColor,
  });

  final String title;
  final String trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: trailingColor ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
