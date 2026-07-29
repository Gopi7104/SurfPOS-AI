import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type scale — Inter throughout. See docs/06_UI_UX_GUIDE.md § 3.
///
/// Weight rules (per design brief): headings are Bold, body is Medium,
/// buttons are SemiBold, numeric displays (prices/totals/metrics) are Bold
/// with tabular figures so digits don't jitter in place as they change.
abstract final class AppTypography {
  static TextStyle _inter(
    double size,
    FontWeight weight, {
    Color color = AppColors.textDark,
    double? height,
    double? letterSpacing,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: fontFeatures,
    );
  }

  // ---------------------------------------------------------------------
  // Headings — Bold
  // ---------------------------------------------------------------------

  /// Splash/onboarding hero text.
  static TextStyle get displayXL =>
      _inter(32, FontWeight.w700, height: 1.15, letterSpacing: -0.5);

  /// Screen titles (e.g. "Dashboard", "Inventory").
  static TextStyle get headingLG =>
      _inter(24, FontWeight.w700, height: 1.2, letterSpacing: -0.3);

  /// Section headers within a screen.
  static TextStyle get headingMD => _inter(18, FontWeight.w700, height: 1.25);

  /// Card titles, list-section labels.
  static TextStyle get headingSM => _inter(16, FontWeight.w700, height: 1.3);

  // ---------------------------------------------------------------------
  // Body — Medium
  // ---------------------------------------------------------------------

  static TextStyle get bodyLG => _inter(16, FontWeight.w500, height: 1.45);
  static TextStyle get bodyMD => _inter(14, FontWeight.w500, height: 1.45);
  static TextStyle get bodySM => _inter(13, FontWeight.w500, height: 1.4);

  /// Timestamps, helper text, field hints.
  static TextStyle get caption =>
      _inter(12, FontWeight.w500, color: AppColors.textGrey, height: 1.35);

  // ---------------------------------------------------------------------
  // Buttons — SemiBold
  // ---------------------------------------------------------------------

  static TextStyle get buttonLG =>
      _inter(16, FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get buttonMD =>
      _inter(14, FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get buttonSM =>
      _inter(13, FontWeight.w600, letterSpacing: 0.1);

  // ---------------------------------------------------------------------
  // Numbers — Bold, tabular figures (prices, totals, KPI stats)
  // ---------------------------------------------------------------------

  static const _tabular = [FontFeature.tabularFigures()];

  /// Grand total on the checkout/payment screens.
  static TextStyle get numberXL => _inter(
        36,
        FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        fontFeatures: _tabular,
      );

  /// Dashboard stat-card primary figure.
  static TextStyle get numberLG =>
      _inter(26, FontWeight.w700, height: 1.15, fontFeatures: _tabular);

  /// Inline prices in lists/cart rows.
  static TextStyle get numberMD =>
      _inter(18, FontWeight.w700, height: 1.2, fontFeatures: _tabular);

  static TextStyle get numberSM =>
      _inter(14, FontWeight.w700, height: 1.2, fontFeatures: _tabular);

  // ---------------------------------------------------------------------
  // ThemeData integration
  // ---------------------------------------------------------------------

  /// Maps the scale above onto Flutter's [TextTheme] slots so every default
  /// Material widget (AppBar titles, Text defaults, etc.) picks up Inter
  /// and the correct weights without every call site needing to reference
  /// [AppTypography] directly.
  static TextTheme buildTextTheme({Color color = AppColors.textDark}) {
    return TextTheme(
      displayLarge: displayXL.copyWith(color: color),
      displayMedium: headingLG.copyWith(color: color),
      displaySmall: headingMD.copyWith(color: color),
      headlineLarge: headingLG.copyWith(color: color),
      headlineMedium: headingMD.copyWith(color: color),
      headlineSmall: headingSM.copyWith(color: color),
      titleLarge: headingSM.copyWith(color: color),
      titleMedium: bodyLG.copyWith(fontWeight: FontWeight.w600, color: color),
      titleSmall: bodyMD.copyWith(fontWeight: FontWeight.w600, color: color),
      bodyLarge: bodyLG.copyWith(color: color),
      bodyMedium: bodyMD.copyWith(color: color),
      bodySmall: bodySM.copyWith(color: color),
      labelLarge: buttonLG.copyWith(color: color),
      labelMedium: buttonMD.copyWith(color: color),
      labelSmall: caption,
    );
  }
}
