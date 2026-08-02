import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';

/// A generic rounded linear progress bar — the primitive every "X relative
/// to Y" visualization in this app (ranked lists, category shares, ...)
/// should share instead of each screen hand-rolling its own
/// `ClipRRect(LinearProgressIndicator(...))`. Animates to [value] on first
/// build/whenever it changes, under 300ms, matching this app's micro-
/// interaction budget.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.color = AppColors.primary,
    this.trackColor = AppColors.disabledSurface,
    this.height = 6,
    super.key,
  });

  /// `0.0`–`1.0`; values outside that range are clamped.
  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: AppMotion.medium,
        curve: AppMotion.curve.standard,
        builder: (context, animatedValue, _) => LinearProgressIndicator(
          value: animatedValue,
          minHeight: height,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
