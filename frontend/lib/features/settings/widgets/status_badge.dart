import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/chips/status_chip.dart';

/// A small dot + label pill — the "Active"/"Connected"/"Offline" badge
/// shown beside a name or title (Merchant Profile's header, a diagnostic
/// card's title row). Reuses [StatusTone] so callers pick the same tone
/// vocabulary as [StatusChip] rather than a second one.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.tone = StatusTone.neutral,
    super.key,
  });

  final String label;
  final StatusTone tone;

  Color get _dotColor => switch (tone) {
        StatusTone.success => AppColors.success,
        StatusTone.warning => AppColors.warning,
        StatusTone.error => AppColors.error,
        StatusTone.neutral => AppColors.textGrey,
      };

  Color get _background => switch (tone) {
        StatusTone.success => AppColors.successContainer,
        StatusTone.warning => AppColors.warningContainer,
        StatusTone.error => AppColors.errorContainer,
        StatusTone.neutral => AppColors.disabledSurface,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption
                .copyWith(color: _dotColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
