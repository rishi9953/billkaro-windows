import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WeeklySalesChart extends StatelessWidget {
  final RxList<double> weeklySales;

  const WeeklySalesChart({super.key, required this.weeklySales});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Obx(() {
        return LineChart(
          _chartData(),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }),
    );
  }

  LineChartData _chartData() {
    return LineChartData(
      minY: 0,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: _titles(),
      lineBarsData: [_line()],
    );
  }

  LineChartBarData _line() {
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      color: Colors.blueAccent,
      barWidth: 3,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.35),
            Colors.blueAccent.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      dotData: FlDotData(show: false),
      spots: _spots(),
    );
  }

  List<FlSpot> _spots() {
    return List.generate(
      weeklySales.length,
      (i) => FlSpot(i.toDouble(), weeklySales[i]),
    );
  }

  FlTitlesData _titles() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 32),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, _) {
            return Text(
              days[value.toInt() % days.length],
              style: const TextStyle(fontSize: 12),
            );
          },
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}
