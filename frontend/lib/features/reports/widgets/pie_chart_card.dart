import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../models/category_breakdown_slice.dart';
import 'empty_reports_view.dart';

/// The Category Breakdown section — an [fl_chart] pie chart of revenue by
/// category, with a legend, or an empty state when there's nothing to
/// break down yet. Same rebuild-only-on-filter-change contract as
/// [ChartCard] — see its header comment.
class PieChartCard extends StatelessWidget {
  const PieChartCard({required this.slices, super.key});

  final List<CategoryBreakdownSlice> slices;

  /// Cycles through existing brand-derived colors only — never an
  /// arbitrary invented hue (see `AppColors`'s own "official colors" rule).
  static const _palette = [
    AppColors.primary,
    AppColors.warning,
    AppColors.success,
    AppColors.primaryLight,
    AppColors.error,
    AppColors.primaryDark,
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Category Breakdown'),
          if (slices.isEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180),
              child: const EmptyReportsView(
                  message: 'No category revenue recorded yet.'),
            )
          else
            RepaintBoundary(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 32,
                        sections: [
                          for (var i = 0; i < slices.length; i++)
                            PieChartSectionData(
                              value: slices[i].revenue,
                              color: _palette[i % _palette.length],
                              radius: 28,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < slices.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
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
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    slices[i].category,
                                    style: AppTypography.caption,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${slices[i].percentage.toStringAsFixed(0)}%',
                                  style: AppTypography.caption
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
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
