import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../buttons/app_primary_button.dart';
import '../buttons/app_secondary_button.dart';

enum AppDialogTone { neutral, success, error, warning }

/// The base dialog every confirmation/alert in the app uses — a tone icon,
/// title, message, and a primary + optional secondary action stacked full
/// width. See docs/06_UI_UX_GUIDE.md § 9.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.message,
    this.tone = AppDialogTone.neutral,
    this.primaryLabel = 'OK',
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String message;
  final AppDialogTone tone;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  (Color, Color, IconData) get _toneStyle => switch (tone) {
        AppDialogTone.success => (
            AppColors.success,
            AppColors.successContainer,
            Icons.check_circle_rounded,
          ),
        AppDialogTone.error => (
            AppColors.error,
            AppColors.errorContainer,
            Icons.error_rounded,
          ),
        AppDialogTone.warning => (
            AppColors.warning,
            AppColors.warningContainer,
            Icons.warning_rounded,
          ),
        AppDialogTone.neutral => (
            AppColors.primary,
            AppColors.primarySubtle,
            Icons.info_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = _toneStyle;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headingMD,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: primaryLabel,
              onPressed: onPrimary ?? () => Navigator.of(context).pop(),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: secondaryLabel!,
                onPressed: onSecondary ?? () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  AppDialogTone tone = AppDialogTone.neutral,
  String primaryLabel = 'OK',
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => AppDialog(
      title: title,
      message: message,
      tone: tone,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    ),
  );
}
