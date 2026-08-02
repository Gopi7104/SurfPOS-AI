import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// A tiny "value + label" pill — e.g. "26 Orders" — for a row of quick
/// glance figures under a hero KPI. [light] switches to a translucent
/// white-on-gradient variant for sitting directly on a
/// [GradientHeroCard]/[AppGradientHeader]'s surface; the default is a
/// tinted-primary variant for use on a plain background.
class StatPill extends StatelessWidget {
  const StatPill({
    required this.value,
    required this.label,
    this.light = false,
    super.key,
  });

  final String value;
  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final background = light
        ? AppColors.white.withValues(alpha: 0.16)
        : AppColors.primarySubtle;
    final valueColor = light ? AppColors.white : AppColors.textDark;
    final labelColor =
        light ? AppColors.white.withValues(alpha: 0.78) : AppColors.textGrey;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppTypography.bodySM
                  .copyWith(color: valueColor, fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(color: labelColor)),
        ],
      ),
    );
  }
}
