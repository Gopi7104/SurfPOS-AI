import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../billing/pages/billing_page.dart';

/// The page-level empty state — shown instead of every chart/KPI section
/// when there is genuinely nothing to analyze yet (no demo data generated,
/// and no real sales history — see `ReportsRepositoryImpl`'s header
/// comment for why that's the default for every merchant today). A
/// layered-circle illustration (existing design tokens only, no new image
/// assets), matching `DashboardActivityEmptyState`'s visual language.
/// "Go to Billing" reuses plain `Navigator.push` — the same pattern
/// `DashboardPage`'s own onboarding CTA already uses — never a change to
/// the app's tab/routing structure.
class ReportsEmptyState extends StatelessWidget {
  const ReportsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LayeredIllustration(),
          const SizedBox(height: AppSpacing.lg),
          Text('No business data available yet',
              textAlign: TextAlign.center, style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Complete your first sale to unlock analytics.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Go to Billing',
            expand: false,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BillingPage()),
            ),
          ),
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
