import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft shadow presets. Every shadow in the app comes from here — never a
/// hand-rolled `BoxShadow` inline — so elevation reads consistently across
/// screens. See docs/06_UI_UX_GUIDE.md § 6.
abstract final class AppShadows {
  /// Resting cards (product cards, list rows lifted off the background).
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.shadowNeutral.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Raised surfaces (bottom sheets, dialogs, the floating cart preview).
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.shadowNeutral.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  /// Primary-tinted "glow" under primary buttons and the FAB — the
  /// premium-fintech colored-shadow look, used sparingly.
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: AppColors.shadowPrimary.withValues(alpha: 0.28),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Subtle inner lift for pressed/selected chip-like surfaces.
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: AppColors.shadowNeutral.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
