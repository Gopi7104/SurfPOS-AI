import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/charts/chart_container.dart';
import '../../../core/widgets/charts/chart_empty_message.dart';
import '../../demo_data/models/demo_business_snapshot.dart';
import '../../demo_data/models/revenue_period.dart';

/// The Revenue Chart section — a bar chart with an interactive Today/Week/
/// Month toggle, each period at its own bucketing (see
/// [DemoBusinessSnapshot.revenueTrend]'s header comment). Rebuilds only
/// itself when the toggle changes — a local `setState`, never the whole
/// Dashboard.
class RevenueChartSection extends StatefulWidget {
  const RevenueChartSection({required this.trendFor, super.key});

  final List<DemoTrendPoint> Function(RevenuePeriod period) trendFor;

  @override
  State<RevenueChartSection> createState() => _RevenueChartSectionState();
}

class _RevenueChartSectionState extends State<RevenueChartSection> {
  RevenuePeriod _period = RevenuePeriod.today;

  @override
  Widget build(BuildContext context) {
    final points = widget.trendFor(_period);
    final hasData = points.any((p) => p.amount > 0);

    return ChartContainer(
      title: 'Revenue',
      trailing: _PeriodToggle(
        period: _period,
        onChanged: (period) => setState(() => _period = period),
      ),
      child: hasData
          ? _RevenueBarChart(points: points)
          : const ChartEmptyMessage(
              message: 'No revenue recorded for this period yet.'),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final RevenuePeriod period;
  final ValueChanged<RevenuePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.disabledSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in RevenuePeriod.values)
            GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve.standard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: option == period ? AppColors.primary : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  option.label,
                  style: AppTypography.caption.copyWith(
                    color:
                        option == period ? AppColors.white : AppColors.textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.points});

  final List<DemoTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        points.fold<double>(0, (max, p) => p.amount > max ? p.amount : max);

    return BarChart(
      BarChartData(
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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              '\$${rod.toY.toStringAsFixed(2)}',
              AppTypography.caption.copyWith(color: AppColors.white),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: points[i].amount,
                color: AppColors.primary,
                width: 18,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ]),
        ],
      ),
    );
  }
}
