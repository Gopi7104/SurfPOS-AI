import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../pages/add_customer_page.dart';

/// The true "zero customers" empty state — a layered-circle illustration
/// (existing design tokens only), matching Reports'/Dashboard's identical
/// visual language. "Add Customer" reuses plain `Navigator.push` to the
/// same [AddCustomerPage] the Hero header's own button already opens —
/// never a new routing path. "Import Customers" is honest about not
/// existing yet (no CSV/contacts package in `pubspec.yaml`) — same
/// "Coming Soon" convention `CustomerLoyaltyCard` already uses for
/// Coupons/Rewards/Referral, rather than silently adding a dependency.
class CustomersIllustratedEmptyState extends StatelessWidget {
  const CustomersIllustratedEmptyState({super.key});

  void _importCustomers(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importing customers is coming soon.')),
    );
  }

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
            'Add your first customer, or they\'ll be captured automatically during billing.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Import Customers',
                  icon: LucideIcons.upload,
                  onPressed: () => _importCustomers(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppPrimaryButton(
                  label: 'Add Customer',
                  icon: LucideIcons.userPlus,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddCustomerPage()),
                  ),
                ),
              ),
            ],
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
