import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/charts/chart_container.dart';
import '../../../core/widgets/charts/chart_empty_message.dart';

/// One donut segment — generic (not `PaymentBreakdownSlice` directly) so
/// this card doesn't depend on `demo_data`; the page converts.
typedef BreakdownSlice = ({String label, double amount, double percentage});

/// The Revenue Breakdown section — a donut chart of revenue by payment
/// method, with a legend. Tapping a segment (or its legend row) highlights
/// it and shows its amount + share in the center — both fields already on
/// [BreakdownSlice], nothing computed fresh. Segments with no revenue at
/// all are omitted rather than shown as an empty sliver.
class RevenueBreakdownCard extends StatefulWidget {
  const RevenueBreakdownCard({required this.slices, super.key});

  final List<BreakdownSlice> slices;

  static const palette = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
    AppColors.primaryLight,
    AppColors.error,
    AppColors.textGrey,
  ];

  @override
  State<RevenueBreakdownCard> createState() => _RevenueBreakdownCardState();
}

class _RevenueBreakdownCardState extends State<RevenueBreakdownCard> {
  int? _selected;

  List<BreakdownSlice> get _visible =>
      widget.slices.where((s) => s.amount > 0).toList();

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final selectedIndex =
        _selected != null && _selected! < visible.length ? _selected : null;
    final selectedSlice = selectedIndex != null ? visible[selectedIndex] : null;

    return ChartContainer(
      title: 'Revenue Breakdown',
      height: 196,
      child: visible.isEmpty
          ? const ChartEmptyMessage(message: 'No payment data recorded yet.')
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 38,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              final index =
                                  response?.touchedSection?.touchedSectionIndex;
                              if (index == null || index < 0) return;
                              setState(() => _selected =
                                  _selected == index ? null : index);
                            },
                          ),
                          sections: [
                            for (var i = 0; i < visible.length; i++)
                              PieChartSectionData(
                                value: visible[i].amount,
                                color: RevenueBreakdownCard.palette[
                                    i % RevenueBreakdownCard.palette.length],
                                radius: selectedIndex == i ? 30 : 26,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      if (selectedSlice != null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                '${selectedSlice.percentage.toStringAsFixed(0)}%',
                                style: AppTypography.headingSM),
                            Text('\$${selectedSlice.amount.toStringAsFixed(0)}',
                                style: AppTypography.caption),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        GestureDetector(
                          onTap: () => setState(
                              () => _selected = _selected == i ? null : i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: RevenueBreakdownCard.palette[i %
                                        RevenueBreakdownCard.palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    visible[i].label,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: selectedIndex == i
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${visible[i].percentage.toStringAsFixed(0)}%',
                                  style: AppTypography.caption
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
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
