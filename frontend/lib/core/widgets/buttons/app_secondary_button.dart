import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Secondary action button — outlined, transparent fill, primary-colored
/// label. Used for "Cancel", "Skip", "Add another item" style actions that
/// shouldn't compete visually with [AppPrimaryButton].
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.isDestructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  /// Red outline/label variant for reversible-but-cautionary actions
  /// (e.g. "Remove item"). For a true destructive confirmation, pair with
  /// `showAppConfirmationDialog` instead of relying on color alone.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return SizedBox(
      width: expand ? double.infinity : null,
      height: AppSpacing.minTapTarget + 8,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: isDestructive ? AppColors.error : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(label, style: AppTypography.buttonLG.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
