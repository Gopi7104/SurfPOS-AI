import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/cards/gradient_hero_card.dart';
import '../../../core/widgets/chips/stat_pill.dart';

/// Customers' new hero — replaces the plain `AppTopBar` title bar. One
/// large animated Total Customers figure plus Active/New This Month
/// [StatPill]s underneath, a search shortcut, and an Add Customer action —
/// same visual language as Reports' `AnalyticsHeroHeader`/Dashboard's
/// `DashboardHeroSection`.
class CustomerHeroHeader extends StatelessWidget {
  const CustomerHeroHeader({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.newThisMonth,
    required this.onSearchTap,
    required this.onAddCustomer,
    super.key,
  });

  final int totalCustomers;
  final int activeCustomers;
  final int newThisMonth;
  final VoidCallback onSearchTap;
  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) {
    return GradientHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Customers',
                  style:
                      AppTypography.headingLG.copyWith(color: AppColors.white),
                ),
              ),
              _HeroIconButton(icon: LucideIcons.search, onTap: onSearchTap),
              const SizedBox(width: AppSpacing.sm),
              _HeroIconButton(icon: LucideIcons.userPlus, onTap: onAddCustomer),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Total Customers',
              style: AppTypography.caption
                  .copyWith(color: AppColors.white.withValues(alpha: 0.78))),
          const SizedBox(height: 4),
          CountUpNumber(
            value: totalCustomers.toDouble(),
            formatter: (v) => v.toStringAsFixed(0),
            style: AppTypography.numberXL.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatPill(value: '$activeCustomers', label: 'Active', light: true),
              StatPill(
                  value: '$newThisMonth', label: 'New This Month', light: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: AppColors.white),
        ),
      ),
    );
  }
}
