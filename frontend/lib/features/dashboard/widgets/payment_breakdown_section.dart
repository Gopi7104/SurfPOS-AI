import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/charts/chart_container.dart';
import '../../../core/widgets/charts/chart_empty_message.dart';
import '../../demo_data/models/payment_breakdown_slice.dart';

/// The Payment Breakdown section — a donut chart of Cash/Card/Mobile
/// Payment/Test revenue share, with a legend. Same brand-derived color
/// cycling rule Reports' own `PieChartCard` follows — never an arbitrary
/// invented hue.
class PaymentBreakdownSection extends StatelessWidget {
  const PaymentBreakdownSection({required this.slices, super.key});

  final List<PaymentBreakdownSlice> slices;

  static const _palette = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
    AppColors.textGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final visible = slices.where((s) => s.amount > 0).toList();

    return ChartContainer(
      title: 'Payment Breakdown',
      height: 196,
      child: visible.isEmpty
          ? const ChartEmptyMessage(message: 'No payments recorded yet.')
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: PieChart(
                    PieChartData(
                      // Touch/tooltip handling deliberately disabled to
                      // match `revenue_chart_section.dart`/
                      // `sales_trend_section.dart`'s own `BarTouchData`/
                      // `LineTouchData(enabled: false)` — this donut was the
                      // one chart on this page still left at fl_chart's
                      // default (touch enabled), which risks the same
                      // gesture-arena competition with the ancestor
                      // ListView's scroll those two comments describe.
                      pieTouchData: PieTouchData(enabled: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      sections: [
                        for (var i = 0; i < slices.length; i++)
                          PieChartSectionData(
                            value: slices[i].amount,
                            color: _palette[i % _palette.length],
                            radius: 26,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < slices.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _palette[i % _palette.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  slices[i].method,
                                  style: AppTypography.bodySM
                                      .copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${slices[i].percentage.toStringAsFixed(0)}%',
                                style: AppTypography.bodySM.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark),
                              ),
                            ],
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
