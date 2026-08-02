import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';

/// Animates a number counting up from 0 to [value] over
/// [AppMotion.medium] (200–250ms) whenever [value] changes — the subtle
/// "numbers animate" touch called for on the Dashboard's hero KPI and
/// metric cards. [formatter] renders the interpolated value as text (e.g.
/// `(v) => '\$${v.toStringAsFixed(0)}'`).
class CountUpNumber extends StatelessWidget {
  const CountUpNumber({
    required this.value,
    required this.formatter,
    required this.style,
    super.key,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: AppMotion.medium,
      curve: AppMotion.curve.standard,
      builder: (context, animatedValue, child) =>
          Text(formatter(animatedValue), style: style),
    );
  }
}
