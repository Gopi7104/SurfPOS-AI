import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// One row of a vertical activity timeline (Recent Transactions, and any
/// other "modern timeline" list) — a colored dot on a connecting line,
/// title/subtitle, and a trailing value/widget. [isLast] hides the line
/// below the dot for the final row in a list.
class TimelineTile extends StatelessWidget {
  const TimelineTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.dotColor = AppColors.primary,
    this.isLast = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color dotColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTypography.bodyMD
                                .copyWith(fontWeight: FontWeight.w600)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: AppTypography.caption),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
