import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../animations/count_up_number.dart';
import 'app_card.dart';

/// One tile in a "bento" metrics layout — variable emphasis via
/// [featured] (bigger icon/number, used for the one metric that should
/// visually dominate the group) rather than every tile being an identical
/// [StatCard]. Distinct from [StatCard]: that one is a uniform-grid KPI
/// card; this one is deliberately asymmetric.
class BentoMetricCard extends StatelessWidget {
  const BentoMetricCard({
    required this.label,
    required this.value,
    required this.numericValue,
    required this.icon,
    this.formatter,
    this.featured = false,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    super.key,
  });

  final String label;

  /// Pre-formatted fallback (used as the format target); [numericValue] +
  /// [formatter] drive the actual animated count-up text.
  final String value;
  final double numericValue;
  final String Function(double value)? formatter;
  final bool featured;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final valueStyle = featured
        ? AppTypography.numberXL.copyWith(color: AppColors.primary)
        : AppTypography.numberSM;

    return AppCard(
      padding: EdgeInsets.all(featured ? AppSpacing.md : AppSpacing.sm + 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: featured ? 40 : 28,
            height: featured ? 40 : 28,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: featured ? 20 : 14, color: iconColor),
          ),
          SizedBox(height: featured ? AppSpacing.sm : AppSpacing.xs),
          formatter == null
              ? Text(value, style: valueStyle)
              : CountUpNumber(
                  value: numericValue,
                  formatter: formatter!,
                  style: valueStyle),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
