import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/charts/chart_container.dart';
import '../../../core/widgets/charts/chart_empty_message.dart';

enum SalesTrendWindow { sevenDays, thirtyDays, ninetyDays, oneYear }

/// A single labeled trend point — deliberately generic (not
/// `reports/models/sales_trend_point.dart` or
/// `demo_data/models/demo_business_snapshot.dart`'s `DemoTrendPoint`) so
/// this card can plot either without depending on both feature modules;
/// the page converts whichever one is active into this shape.
typedef TrendPoint = ({String label, double amount});

/// The Sales Trend section — a gradient-filled line chart with a 7D/30D/
/// 90D/1Y window toggle. The toggle only slices [points] (whatever history
/// is actually available today — at most demo's 14 days; see
/// `DemoBusinessSnapshot.salesTrend`'s header comment); it never invents
/// extra history to fill a wider window. Requesting a window wider than
/// the available history shows every point that exists plus an honest
/// note, rather than fabricating a longer trend.
class SalesTrendCard extends StatefulWidget {
  const SalesTrendCard({required this.points, super.key});

  final List<TrendPoint> points;

  @override
  State<SalesTrendCard> createState() => _SalesTrendCardState();
}

class _SalesTrendCardState extends State<SalesTrendCard> {
  SalesTrendWindow _window = SalesTrendWindow.sevenDays;

  int get _windowDays => switch (_window) {
        SalesTrendWindow.sevenDays => 7,
        SalesTrendWindow.thirtyDays => 30,
        SalesTrendWindow.ninetyDays => 90,
        SalesTrendWindow.oneYear => 365,
      };

  List<TrendPoint> get _windowed {
    final all = widget.points;
    if (all.length <= _windowDays) return all;
    return all.sublist(all.length - _windowDays);
  }

  @override
  Widget build(BuildContext context) {
    final windowed = _windowed;
    final hasData = windowed.any((p) => p.amount > 0);
    final isTruncated =
        widget.points.isNotEmpty && widget.points.length < _windowDays;

    return ChartContainer(
      title: 'Sales Trend',
      height: isTruncated ? 244 : 220,
      trailing: _WindowToggle(
        window: _window,
        onChanged: (window) => setState(() => _window = window),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: hasData
                ? _LineChart(points: windowed)
                : const ChartEmptyMessage(
                    message: 'No sales recorded for this period yet.'),
          ),
          if (isTruncated)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Showing all ${widget.points.length} days available — longer history isn\'t tracked yet.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _WindowToggle extends StatelessWidget {
  const _WindowToggle({required this.window, required this.onChanged});

  final SalesTrendWindow window;
  final ValueChanged<SalesTrendWindow> onChanged;

  String _label(SalesTrendWindow w) => switch (w) {
        SalesTrendWindow.sevenDays => '7D',
        SalesTrendWindow.thirtyDays => '30D',
        SalesTrendWindow.ninetyDays => '90D',
        SalesTrendWindow.oneYear => '1Y',
      };

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
          for (final option in SalesTrendWindow.values)
            GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve.standard,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: option == window ? AppColors.primary : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _label(option),
                  style: AppTypography.caption.copyWith(
                    color:
                        option == window ? AppColors.white : AppColors.textGrey,
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

class _LineChart extends StatelessWidget {
  const _LineChart({required this.points});

  final List<TrendPoint> points;

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
              interval:
                  (points.length / 4).ceilToDouble().clamp(1, double.infinity),
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
                FlSpot(i.toDouble(), points[i].amount)
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primarySubtle.withValues(alpha: 0.7),
                  AppColors.primarySubtle.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
