import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/charts/chart_container.dart';
import '../../../core/widgets/charts/chart_empty_message.dart';
import '../../demo_data/models/demo_business_snapshot.dart';

/// The Sales Trend section — a 14-day line chart, always at daily
/// granularity regardless of the Revenue Chart's own Today/Week/Month
/// toggle (see [DemoBusinessSnapshot.salesTrend]).
class SalesTrendSection extends StatelessWidget {
  const SalesTrendSection({required this.points, super.key});

  final List<DemoTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.amount > 0);

    return ChartContainer(
      title: 'Sales Trend (14 days)',
      child: hasData
          ? _LineChart(points: points)
          : const ChartEmptyMessage(message: 'No sales recorded yet.'),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.points});

  final List<DemoTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        points.fold<double>(0, (max, p) => p.amount > max ? p.amount : max);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxAmount == 0 ? 1 : maxAmount * 1.2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 4).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child:
                      Text(points[index].label, style: AppTypography.caption),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryDark,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '\$${spot.y.toStringAsFixed(2)}',
                  AppTypography.caption.copyWith(color: AppColors.white),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].amount),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primarySubtle.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
