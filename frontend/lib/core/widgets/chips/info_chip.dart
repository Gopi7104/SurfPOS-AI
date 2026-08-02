import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import 'status_chip.dart';

/// A compact icon+text row for a single fact or insight (e.g. "Sales up
/// 14% this week", "Low stock on 3 products") — reuses [StatusTone] so
/// callers pick the same tone vocabulary as [StatusChip] rather than a
/// second one. Distinct from [InsightCard] (reserved for AI Assistant/AI
/// Insight surfaces and their Cream Soda accent — see its own header
/// comment): this is the general-purpose "one line of insight" building
/// block used anywhere else (Dashboard's Business Insights, summaries).
class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.icon,
    required this.label,
    this.tone = StatusTone.neutral,
    super.key,
  });

  final IconData icon;
  final String label;
  final StatusTone tone;

  Color get _foreground => switch (tone) {
        StatusTone.success => AppColors.success,
        StatusTone.warning => AppColors.warning,
        StatusTone.error => AppColors.error,
        StatusTone.neutral => AppColors.primary,
      };

  Color get _background => switch (tone) {
        StatusTone.success => AppColors.successContainer,
        StatusTone.warning => AppColors.warningContainer,
        StatusTone.error => AppColors.errorContainer,
        StatusTone.neutral => AppColors.primarySubtle,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _foreground),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySM.copyWith(
                  color: AppColors.textDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
