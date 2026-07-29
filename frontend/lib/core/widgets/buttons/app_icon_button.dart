import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';

enum AppIconButtonSize { sm, md, lg }

/// Rounded icon-container button — every standalone icon action in the app
/// (back, close, scan, notifications bell) uses this, never a bare
/// [Icon]/[IconButton], so icon touch targets stay visually consistent.
/// See docs/06_UI_UX_GUIDE.md § 5.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onTap,
    this.size = AppIconButtonSize.md,
    this.selected = false,
    this.filled = true,
    this.badge = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final AppIconButtonSize size;

  /// Filled-primary appearance (e.g. active nav state).
  final bool selected;

  /// Whether the resting state has a subtle container fill (true) or is
  /// icon-only with no background (false) — icon-only is used on top of
  /// gradient headers where a light container would clash.
  final bool filled;

  /// Small red dot, e.g. unread notifications.
  final bool badge;

  double get _boxSize => switch (size) {
        AppIconButtonSize.sm => 36,
        AppIconButtonSize.md => 44,
        AppIconButtonSize.lg => 52,
      };

  double get _iconSize => switch (size) {
        AppIconButtonSize.sm => 18,
        AppIconButtonSize.md => 20,
        AppIconButtonSize.lg => 24,
      };

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? AppColors.primary
        : (filled ? AppColors.primarySubtle : Colors.transparent);
    final Color iconColor = selected ? AppColors.white : AppColors.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              height: _boxSize,
              width: _boxSize,
              child: Icon(icon, size: _iconSize, color: iconColor),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              height: 9,
              width: 9,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.white, width: 1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
