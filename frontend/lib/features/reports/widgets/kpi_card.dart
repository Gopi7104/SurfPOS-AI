import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/animations/count_up_number.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/charts/mini_sparkline.dart';

/// One KPI tile — icon, animated value (or an honest "—" placeholder when
/// there's no real data source for this metric yet), an optional trend
/// pill, and an optional mini sparkline. [value]/[sparklineValues] being
/// null/empty is the expected, deliberate "not tracked yet" state — never
/// filled with an invented number.
class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.icon,
    this.value,
    this.formatter,
    this.growthPercent,
    this.sparklineValues = const [],
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySubtle,
    super.key,
  });

  final String label;
  final IconData icon;

  /// Null renders the "coming soon" placeholder state instead of a number.
  final double? value;
  final String Function(double value)? formatter;
  final double? growthPercent;
  final List<double> sparklineValues;
  final Color iconColor;
  final Color iconBackground;

  bool get _hasData => value != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (growthPercent != null) _TrendPill(growth: growthPercent!),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _hasData
              ? CountUpNumber(
                  value: value!,
                  formatter: formatter ?? (v) => v.toStringAsFixed(0),
                  style: AppTypography.numberSM,
                )
              : Text('—',
                  style: AppTypography.numberSM
                      .copyWith(color: AppColors.disabledText)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (_hasData && sparklineValues.length >= 2) ...[
            const SizedBox(height: AppSpacing.xs),
            MiniSparkline(
                values: sparklineValues, color: iconColor, height: 26),
          ] else if (!_hasData) ...[
            const SizedBox(height: 2),
            Text(
              'Coming soon',
              style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.growth});

  final double growth;

  @override
  Widget build(BuildContext context) {
    final isUp = growth >= 0;
    final color = isUp ? AppColors.success : AppColors.error;
    final background =
        isUp ? AppColors.successContainer : AppColors.errorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          Text('${growth.abs().toStringAsFixed(0)}%',
              style: AppTypography.caption
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
