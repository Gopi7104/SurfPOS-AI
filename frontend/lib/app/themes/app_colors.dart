import 'package:flutter/material.dart';

/// Brand palette — see docs/06_UI_UX_GUIDE.md § 2 and .claude/decision.md.
///
/// Only [primary], [secondary], [success], [error], [warning], [white],
/// [background], [textDark], [textGrey], and [border] are the official
/// brand colors. Every other value on this class is a *derived* tint/shade
/// used to build containers, gradients, and shadows without inventing new
/// unofficial brand hues.
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Official brand colors
  // ---------------------------------------------------------------------

  /// Blueberry — app bar, primary buttons, active nav, icons, charts.
  static const Color primary = Color(0xFF243B8F);

  /// Cream Soda — dashboard highlight cards, empty states, AI assistant.
  /// Never use as a primary surface color; accent only (see usage rule in
  /// docs/06_UI_UX_GUIDE.md § 2).
  static const Color secondary = Color(0xFFFFF0C9);

  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);

  static const Color white = Color(0xFFFFFFFF);

  /// App scaffold background — never pure white, keeps cards feeling
  /// "lifted" against it.
  static const Color background = Color(0xFFF8F9FC);

  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color border = Color(0xFFE6EAF2);

  // ---------------------------------------------------------------------
  // Derived — primary tints/shades (buttons, pressed/disabled states)
  // ---------------------------------------------------------------------

  static const Color primaryDark = Color(0xFF1A2C6B);
  static const Color primaryLight = Color(0xFF3D57B8);

  /// Very light primary tint — selected nav backgrounds, subtle highlight
  /// chips, icon container backgrounds on light surfaces.
  static const Color primarySubtle = Color(0xFFEBEEFA);

  /// A secondary "surface" tint that keeps Cream Soda usable in dense
  /// contexts without overpowering the page (accessory backgrounds only).
  static const Color secondarySubtle = Color(0xFFFFF9E8);

  // ---------------------------------------------------------------------
  // Derived — semantic containers (badges, banners, chips)
  // ---------------------------------------------------------------------

  static const Color successContainer = Color(0xFFE6F4EA);
  static const Color errorContainer = Color(0xFFFDEAEA);
  static const Color warningContainer = Color(0xFFFFF3D6);

  // ---------------------------------------------------------------------
  // Derived — surfaces, dividers, overlays
  // ---------------------------------------------------------------------

  static const Color surface = white;
  static const Color divider = border;

  /// Modal/bottom-sheet/dialog scrim.
  static const Color scrim = Color(0x66101322);

  /// Disabled control fill.
  static const Color disabledSurface = Color(0xFFEDEFF4);
  static const Color disabledText = Color(0xFFA3AAB8);

  // ---------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------

  /// The signature gradient — headers, FAB, splash background, primary
  /// hero surfaces. Deliberately subtle (not a rainbow gradient) to keep
  /// the premium-fintech feel.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Soft Cream Soda wash — used sparingly behind AI Assistant / insight
  /// surfaces, never as a full-screen background.
  static const LinearGradient secondaryWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondary, secondarySubtle],
  );

  // ---------------------------------------------------------------------
  // Shadow tint
  // ---------------------------------------------------------------------

  /// Neutral shadow tint for standard elevation (see [AppShadows]).
  static const Color shadowNeutral = Color(0xFF1A1A1A);

  /// Primary-tinted "glow" shadow used under primary buttons / the FAB for
  /// a premium, colored-elevation look instead of flat grey shadows.
  static const Color shadowPrimary = Color(0xFF243B8F);
}
