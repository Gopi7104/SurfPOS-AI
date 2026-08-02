import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';

/// Peak Business Hours — always a placeholder today. No hourly-bucketed
/// sale distribution exists anywhere yet (neither `ReportsSnapshot` nor
/// `DemoBusinessSnapshot` expose one — `DemoSale.time` is a raw timestamp
/// per record, not an hourly rollup), so a real heatmap isn't honestly
/// possible without adding a new aggregate, which is out of scope for a
/// presentation-only redesign. Kept visually "designed" (a dimmed grid
/// mirroring the eventual Morning/Afternoon/Evening/Night × hour shape)
/// rather than a bare empty box.
class PeakHoursCard extends StatelessWidget {
  const PeakHoursCard({super.key});

  static const _rowLabels = ['Morning', 'Afternoon', 'Evening', 'Night'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Peak Business Hours'),
          Opacity(
            opacity: 0.35,
            child: Column(
              children: [
                for (final label in _rowLabels)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 68,
                            child: Text(label, style: AppTypography.caption)),
                        Expanded(
                          child: Row(
                            children: [
                              for (var i = 0; i < 8; i++)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                          alpha: 0.15 + (i % 4) * 0.12),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Peak-hours analysis is coming soon.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
