import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';

/// A tiny, axis-free trend line — the compact "mini chart" a KPI card
/// shows beside its headline number. Purely a scaled line through
/// [values] (oldest first); like every other chart in this app
/// ([ChartContainer]'s children), the y-scale (`maxY`) is derived fresh
/// from the data it's given — the same local axis-scaling arithmetic
/// `ChartCard`/`RevenueChartSection` already do, not a new business
/// calculation. Renders nothing (a blank box) when there are fewer than 2
/// points, since a single point can't draw a trend line.
class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    required this.values,
    this.color = AppColors.primary,
    this.height = 32,
    super.key,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);

    final maxValue = values.fold<double>(0, (max, v) => v > max ? v : max);
    final minValue =
        values.fold<double>(maxValue, (min, v) => v < min ? v : min);
    final range = maxValue - minValue;

    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            minY: range == 0 ? minValue - 1 : minValue,
            maxY: range == 0 ? maxValue + 1 : maxValue,
            lineTouchData: const LineTouchData(enabled: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i]),
                ],
                isCurved: true,
                color: color,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
