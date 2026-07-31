import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Semantic tone for a [StatusChip] — maps to the app's existing
/// success/warning/error/neutral container colors (see [AppColors]), never
/// a one-off color invented per call site.
enum StatusTone { success, warning, error, neutral }

/// A small colored label for any status value (application status, merchant
/// status, store status, connectivity). Generic and reusable — callers
/// decide the tone, this widget only renders it consistently.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, this.tone = StatusTone.neutral, super.key});

  final String label;
  final StatusTone tone;

  Color get _foreground => switch (tone) {
        StatusTone.success => AppColors.success,
        StatusTone.warning => AppColors.warning,
        StatusTone.error => AppColors.error,
        StatusTone.neutral => AppColors.textGrey,
      };

  Color get _background => switch (tone) {
        StatusTone.success => AppColors.successContainer,
        StatusTone.warning => AppColors.warningContainer,
        StatusTone.error => AppColors.errorContainer,
        StatusTone.neutral => AppColors.disabledSurface,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: _foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
