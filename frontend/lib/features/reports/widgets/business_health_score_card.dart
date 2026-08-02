import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../../core/widgets/indicators/circular_score_gauge.dart';
import '../../../core/widgets/progress/app_progress_bar.dart';

/// Business Health Score — always a placeholder today. No merchant-facing
/// scoring model (weighting revenue/growth/inventory/orders/customers
/// into one 0–100 figure) exists anywhere in this app yet — inventing one
/// would be a new business rule, not a presentation change, so this stays
/// an honest "not available" state per the redesign brief.
class BusinessHealthScoreCard extends StatelessWidget {
  const BusinessHealthScoreCard({super.key});

  static const _rows = [
    'Revenue',
    'Growth',
    'Inventory',
    'Orders',
    'Customers'
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Business Health Score'),
          const Center(child: CircularScoreGauge(score: null)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Not available yet',
            textAlign: TextAlign.center,
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final label in _rows) ...[
            Row(
              children: [
                SizedBox(
                    width: 88, child: Text(label, style: AppTypography.bodySM)),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Opacity(
                    opacity: 0.3,
                    child: AppProgressBar(value: 0, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const StatusChip(label: 'No Data', tone: StatusTone.neutral),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
