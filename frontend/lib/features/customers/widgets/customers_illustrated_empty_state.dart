import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../billing/pages/billing_page.dart';

/// The true "zero customers" empty state — a layered-circle illustration
/// (existing design tokens only), matching Reports'/Dashboard's identical
/// visual language. "Go to Billing" reuses plain `Navigator.push` — the
/// same pattern `ReportsEmptyState`/`DashboardPage`'s onboarding CTA
/// already use — never a change to the app's tab/routing structure.
class CustomersIllustratedEmptyState extends StatelessWidget {
  const CustomersIllustratedEmptyState({super.key});

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
          Text('No customers yet',
              textAlign: TextAlign.center, style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Customer information is automatically captured during billing.',
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
          const Icon(LucideIcons.users, size: 32, color: AppColors.primary),
        ],
      ),
    );
  }
}
