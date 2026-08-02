import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../models/customer_model.dart';

/// Loyalty — Points and Membership Tier are real, already-existing fields
/// (`CustomerModel.loyaltyPoints`/`lifetimePoints`/`membershipTier`, the
/// same values the old "Loyalty" info block already showed). Coupons,
/// Rewards, and Referral have no backing concept anywhere in this app —
/// they render as honest "Coming Soon" placeholders per the CRM redesign
/// brief, never a fabricated count.
class CustomerLoyaltyCard extends StatelessWidget {
  const CustomerLoyaltyCard({required this.customer, super.key});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Loyalty',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _LoyaltyTile(
                  icon: LucideIcons.star,
                  label: 'Points',
                  value: '${customer.loyaltyPoints}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _LoyaltyTile(
                  icon: LucideIcons.medal,
                  label: 'Tier',
                  value: customer.membershipTier.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Expanded(
                  child: _LoyaltyTile(
                      icon: LucideIcons.ticket,
                      label: 'Coupons',
                      comingSoon: true)),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _LoyaltyTile(
                      icon: LucideIcons.gift,
                      label: 'Rewards',
                      comingSoon: true)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _LoyaltyTile(
              icon: LucideIcons.share2,
              label: 'Referral Program',
              comingSoon: true,
              full: true),
        ],
      ),
    );
  }
}

class _LoyaltyTile extends StatelessWidget {
  const _LoyaltyTile({
    required this.icon,
    required this.label,
    this.value,
    this.comingSoon = false,
    this.full = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool comingSoon;
  final bool full;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: comingSoon ? AppColors.disabledSurface : AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon,
              size: 18,
              color: comingSoon ? AppColors.disabledText : AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.caption),
                Text(
                  comingSoon ? 'Coming Soon' : (value ?? '—'),
                  style: AppTypography.bodySM.copyWith(
                    fontWeight: FontWeight.w700,
                    color: comingSoon
                        ? AppColors.disabledText
                        : AppColors.textDark,
                    fontStyle: comingSoon ? FontStyle.italic : FontStyle.normal,
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
