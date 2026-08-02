import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_typography.dart';

/// A bare label/value pair with no card chrome of its own — for embedding a
/// number inside something else's surface (a [ChartContainer]'s header
/// total, a legend row's figure) where a full [StatCard] would be too
/// heavy. Distinct from [StatCard]: that one **is** the card; this is
/// meant to sit inside one.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
    this.alignment = CrossAxisAlignment.start,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.numberMD.copyWith(color: valueColor)),
      ],
    );
  }
}
