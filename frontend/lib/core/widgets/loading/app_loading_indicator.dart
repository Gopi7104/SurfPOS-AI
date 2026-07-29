import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Centered circular progress indicator with an optional label — used for
/// short, indeterminate waits (<2s). For anything longer or content-shaped,
/// prefer [SkeletonBox]/skeleton placeholders instead (see
/// docs/06_UI_UX_GUIDE.md § 7).
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({this.label, this.size = 32, super.key});

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              label!,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen variant — background-filled loading state for an entire
/// route (see Loading Screens in the design brief).
class AppFullScreenLoader extends StatelessWidget {
  const AppFullScreenLoader({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: AppLoadingIndicator(label: label),
    );
  }
}
