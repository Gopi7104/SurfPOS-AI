import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// A large circular "score out of [max]" gauge — Business Health Score's
/// headline figure. When [score] is null, renders a flat, neutral-grey
/// ring with a dash instead of a number — the "unavailable" state, never a
/// fabricated score.
class CircularScoreGauge extends StatelessWidget {
  const CircularScoreGauge({
    required this.score,
    this.max = 100,
    this.size = 140,
    this.color = AppColors.primary,
    super.key,
  });

  final double? score;
  final double max;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = score;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(
            begin: 0, end: value == null ? 0 : (value / max).clamp(0.0, 1.0)),
        duration: AppMotion.medium,
        curve: AppMotion.curve.standard,
        builder: (context, animatedValue, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value == null ? 1 : animatedValue,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.disabledSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    value == null ? AppColors.disabledSurface : color,
                  ),
                ),
              ),
              value == null
                  ? Text('—',
                      style: AppTypography.numberXL
                          .copyWith(color: AppColors.disabledText))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(value.toStringAsFixed(0),
                            style: AppTypography.numberXL),
                        Text('/ ${max.toStringAsFixed(0)}',
                            style: AppTypography.caption),
                      ],
                    ),
            ],
          );
        },
      ),
    );
  }
}
