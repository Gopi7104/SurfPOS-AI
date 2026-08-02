import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/app_card.dart';

/// Shown in place of the sales-shaped sections (Revenue/Sales Trend/
/// Payment Breakdown/Top Products/Recent Transactions/Insights) until
/// there's something to show — real sales history doesn't exist anywhere
/// in this app yet (see `DemoDataController`'s header comment), so this is
/// the expected state for a brand-new merchant. A layered-circle
/// illustration (built purely from existing design tokens, no new image
/// assets) rather than a bare icon, so this never reads as "just a blank
/// widget". [onGenerateDemo] is only ever non-null in development builds —
/// "Generate Demo Business" is a developer-only action (see Settings'
/// Developer section).
class DashboardActivityEmptyState extends StatelessWidget {
  const DashboardActivityEmptyState({this.onGenerateDemo, super.key});

  final VoidCallback? onGenerateDemo;

  @override
  Widget build(BuildContext context) {
    final hasAction = onGenerateDemo != null;

    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LayeredIllustration(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No business activity yet',
            textAlign: TextAlign.center,
            style: AppTypography.headingMD,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasAction
                ? 'Generate a demo business to preview Revenue, Sales Trend, and Insights on this Dashboard.'
                : 'Sales activity will appear here once you start billing.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
          ),
          if (hasAction) ...[
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Generate Demo Data',
              onPressed: onGenerateDemo,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _LayeredIllustration extends StatelessWidget {
  const _LayeredIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
                color: AppColors.primarySubtle, shape: BoxShape.circle),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(LucideIcons.barChart3, size: 32, color: AppColors.primary),
        ],
      ),
    );
  }
}
