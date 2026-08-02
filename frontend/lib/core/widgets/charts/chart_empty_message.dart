import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// A centered icon + message for when a [ChartContainer]'s data is empty —
/// lighter-weight than the full-page [EmptyState] (no title/action), meant
/// to sit inside a chart's own fixed-height plot area.
class ChartEmptyMessage extends StatelessWidget {
  const ChartEmptyMessage({this.message = 'Nothing to show yet.', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.barChart3,
              size: 28, color: AppColors.textGrey),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              style: AppTypography.bodySM.copyWith(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
