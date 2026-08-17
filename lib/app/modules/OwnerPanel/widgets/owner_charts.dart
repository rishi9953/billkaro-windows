import 'package:billkaro/app/modules/OwnerPanel/models/outlet_metrics.dart';
import 'package:billkaro/app/modules/OwnerPanel/owner_panel_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:fl_chart/fl_chart.dart';

class OwnerSalesTrendChart extends StatelessWidget {
  const OwnerSalesTrendChart({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      final data = s.weekTrend;
      final labels = s.weekLabels;
      final total = data.fold<double>(0, (a, b) => a + b);
      final maxV = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
      final chartMax = (maxV <= 0 ? 1000.0 : maxV) * 1.2;

      return _ChartCard(
        title: 'Sales trend',
        subtitle: 'Combined 7-day performance across outlets',
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatOwnerMoney(total),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColor.primary,
              ),
            ),
            Text(
              '7-day total',
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
          ],
        ),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: chartMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMax / 4,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: chartMax / 4,
                    getTitlesWidget: (value, meta) {
                      if (value <= 0 || value >= chartMax) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        formatOwnerMoney(value),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      final isToday = i == labels.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w600,
                            color: isToday
                                ? AppColor.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColor.primary,
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          formatOwnerMoneyFull(s.y),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < data.length; i++)
                      FlSpot(i.toDouble(), data[i]),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.28,
                  color: AppColor.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      final isLast = index == data.length - 1;
                      return FlDotCirclePainter(
                        radius: isLast ? 4.5 : 3,
                        color: Colors.white,
                        strokeWidth: isLast ? 2.5 : 2,
                        strokeColor: AppColor.primary,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColor.primary.withOpacity(0.22),
                        AppColor.primary.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class OwnerOutletComparisonChart extends StatelessWidget {
  const OwnerOutletComparisonChart({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final range = controller.selectedRange.value;
      final ranked = controller.rankedBySelectedRange;
      final top = ranked.take(6).toList();
      final maxSales = top.isEmpty
          ? 1.0
          : top
              .map((e) => e.salesFor(range))
              .fold<double>(0, (a, b) => a > b ? a : b);
      final chartMax = (maxSales <= 0 ? 1000.0 : maxSales) * 1.15;

      return _ChartCard(
        title: 'Outlet comparison',
        subtitle: _rangeSubtitle(range),
        trailing: _RangeChips(controller: controller),
        child: top.isEmpty
            ? SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'No sales in this period',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: 28.0 * top.length + 24,
                child: BarChart(
                  BarChartData(
                    maxY: chartMax,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= top.length) {
                              return const SizedBox.shrink();
                            }
                            final name = top[i].name;
                            final short = name.length > 8
                                ? '${name.substring(0, 8)}…'
                                : name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                short,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColor.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final m = top[group.x];
                          return BarTooltipItem(
                            '${m.name}\n${formatOwnerMoneyFull(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < top.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: top[i].salesFor(range),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColor.chartPalette[
                                      i % AppColor.chartPalette.length],
                                  AppColor.chartPalette[
                                          i % AppColor.chartPalette.length]
                                      .withOpacity(0.75),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      );
    });
  }

  String _rangeSubtitle(OwnerDashRange range) {
    switch (range) {
      case OwnerDashRange.today:
        return 'Today’s sales by outlet';
      case OwnerDashRange.week:
        return 'Last 7 days sales by outlet';
      case OwnerDashRange.month:
        return 'Last 30 days sales by outlet';
    }
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedRange.value;
      Widget chip(String label, OwnerDashRange range) {
        final active = selected == range;
        return GestureDetector(
          onTap: () => controller.setRange(range),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppColor.primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('Today', OwnerDashRange.today),
          const SizedBox(width: 6),
          chip('7D', OwnerDashRange.week),
          const SizedBox(width: 6),
          chip('30D', OwnerDashRange.month),
        ],
      );
    });
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

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
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
