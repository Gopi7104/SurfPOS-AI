import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';

/// Wraps a Settings section/card in a subtle fade + slide-up entrance
/// (200-250ms, matches [AppMotion.medium]) — gated on the user's own
/// "Animations" preference ([SettingsData.animationsEnabled]) rather than
/// always-on, so that switch tile finally does something.
class SettingsFadeIn extends StatelessWidget {
  const SettingsFadeIn({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.curve.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, (1 - value) * 10), child: child),
      ),
      child: child,
    );
  }
}
