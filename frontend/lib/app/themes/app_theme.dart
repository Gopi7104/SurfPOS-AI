import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles every design token into a single [ThemeData]. This is the
/// **only** place `ThemeData`/component themes are constructed — screens
/// and widgets always read from `Theme.of(context)` or the token classes
/// directly, never redefine a color/style inline. See docs/06_UI_UX_GUIDE.md
/// and docs/07_CODING_RULES.md § 13.
abstract final class AppTheme {
  /// A dark counterpart for [light] — added for Settings' Theme preference
  /// (Phase 7). Screens across this app read fixed `AppColors` constants
  /// directly rather than `Theme.of(context)` (by this class's own design
  /// rule above), so switching to this only actually re-themes the parts
  /// of the app that already go through `ThemeData`/`Theme.of(context)`
  /// (default Material chrome, text selection, etc.) — most already-built
  /// screens keep their current light-styled look. Documented explicitly
  /// rather than silently overselling "full dark mode".
  static ThemeData get dark {
    final base = light;
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121319),
      canvasColor: const Color(0xFF121319),
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1E27),
        onSurface: AppColors.white,
      ),
      cardTheme: base.cardTheme.copyWith(color: const Color(0xFF1C1E27)),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: const Color(0xFF1C1E27),
        contentTextStyle:
            base.dialogTheme.contentTextStyle?.copyWith(color: AppColors.white),
      ),
    );
  }

  static ThemeData get light {
    final textTheme = AppTypography.buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textDark,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textDark,
      ),
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ---------------------------------------------------------------
      // App bar
      // ---------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:
            AppTypography.headingSM.copyWith(color: AppColors.white),
        iconTheme: const IconThemeData(color: AppColors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ---------------------------------------------------------------
      // Buttons
      // ---------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.disabledSurface,
          disabledForegroundColor: AppColors.disabledText,
          textStyle: AppTypography.buttonLG,
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget + 8),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledText,
          textStyle: AppTypography.buttonLG,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget + 8),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.buttonMD,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primarySubtle,
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      // ---------------------------------------------------------------
      // Inputs
      // ---------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
        labelStyle: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // ---------------------------------------------------------------
      // Surfaces
      // ---------------------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.headingMD,
        contentTextStyle:
            AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        showDragHandle: false,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySubtle,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.disabledSurface,
        labelStyle: AppTypography.bodySM.copyWith(color: AppColors.primary),
        secondaryLabelStyle:
            AppTypography.bodySM.copyWith(color: AppColors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide.none,
        ),
      ),

      // ---------------------------------------------------------------
      // Navigation & feedback
      // ---------------------------------------------------------------
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: AppTypography.bodyMD.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySubtle,
        circularTrackColor: AppColors.primarySubtle,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTypography.caption.copyWith(color: AppColors.white),
      ),
    );
  }
}
