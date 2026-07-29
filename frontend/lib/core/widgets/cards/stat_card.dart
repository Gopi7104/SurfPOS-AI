import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import 'app_card.dart';

enum StatTrend { up, down, flat }

/// Dashboard KPI card — icon, label, a bold tabular-figure value, and an
/// optional trend pill. Used for "Today's Sales", "Transactions", etc.
/// See docs/05_FEATURES.md § 3 (Dashboard).
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.trendLabel,
    this.trend = StatTrend.flat,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trendLabel;
  final StatTrend trend;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (trendLabel != null)
                _TrendPill(trend: trend, label: trendLabel!),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.numberLG),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend, required this.label});

  final StatTrend trend;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (trend) {
      StatTrend.up => AppColors.success,
      StatTrend.down => AppColors.error,
      StatTrend.flat => AppColors.textGrey,
    };
    final Color bg = switch (trend) {
      StatTrend.up => AppColors.successContainer,
      StatTrend.down => AppColors.errorContainer,
      StatTrend.flat => AppColors.disabledSurface,
    };
    final IconData arrow = switch (trend) {
      StatTrend.up => Icons.arrow_upward_rounded,
      StatTrend.down => Icons.arrow_downward_rounded,
      StatTrend.flat => Icons.remove_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(arrow, size: 12, color: color),
          const SizedBox(width: 2),
          Text(label, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
