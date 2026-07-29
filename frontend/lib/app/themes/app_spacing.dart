import 'package:flutter/animation.dart';

/// 8-point spacing scale. See docs/06_UI_UX_GUIDE.md § 4.
///
/// Always compose margins/padding from these constants — never a raw
/// numeric literal in a widget (see docs/06_UI_UX_GUIDE.md § 11).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Large hero/section breaks (splash, onboarding, empty states).
  static const double xxl = 48;

  /// Standard horizontal screen margin.
  static const double screenPadding = md;

  /// Minimum tappable target — matches platform accessibility guidance.
  static const double minTapTarget = 48;
}

/// Corner-radius scale. Design brief calls for 18–24px rounded corners —
/// this scale stays inside that band for surfaces, with a small radius for
/// compact controls and a pill radius for chips/badges.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 22;
  static const double xl = 24;

  /// Bottom-sheet / large modal top corners.
  static const double sheet = 28;

  /// Fully-rounded pill (chips, badges, segmented controls).
  static const double pill = 999;
}

/// Motion constants — durations/curves for the micro-animations called for
/// throughout the design brief (page transitions, card entrances, button
/// feedback). See docs/06_UI_UX_GUIDE.md § 7.
abstract final class AppMotion {
  /// Button press / icon toggle feedback.
  static const Duration fast = Duration(milliseconds: 150);

  /// Card/list-item entrance, expand/collapse.
  static const Duration medium = Duration(milliseconds: 250);

  /// Screen-to-screen transitions.
  static const Duration screen = Duration(milliseconds: 350);

  /// Skeleton shimmer sweep.
  static const Duration shimmer = Duration(milliseconds: 1400);

  static const curve = _AppCurves();
}

class _AppCurves {
  const _AppCurves();

  Curve get standard => Curves.easeOutCubic;
  Curve get enter => Curves.easeOut;
  Curve get exit => Curves.easeIn;
  Curve get emphasized => Curves.easeOutBack;
}
