import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../models/sales_trend_point.dart';
import 'empty_reports_view.dart';

/// The Sales Chart section — an [fl_chart] line chart of [points], or an
/// empty state when there's nothing to plot yet. [points] is the only
/// input that ever changes this widget's output, and it's an
/// [immutable value from `ReportsState`][ReportsState.snapshot] rather
/// than anything read from a live stream — so this rebuilds exactly when
/// [ReportsController]'s state changes (i.e. on filter change), never on
/// an unrelated rebuild of its parent. Wrapped in a [RepaintBoundary] so
/// the chart's own repaints never bleed into sibling sections' layers.
class ChartCard extends StatelessWidget {
  const ChartCard({required this.title, required this.points, super.key});

  final String title;
  final List<SalesTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: points.isEmpty
                ? const EmptyReportsView(
                    message: 'No sales recorded for this period yet.')
                : SizedBox(
                    height: 220,
                    child: RepaintBoundary(child: _Chart(points: points)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.points});

  final List<SalesTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.fold<double>(
        0, (max, point) => point.amount > max ? point.amount : max);

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
