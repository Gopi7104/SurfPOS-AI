import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Shown when the lookup itself failed — no internet, a timeout, or an
/// invalid barcode (see "ERROR HANDLING") — [message] is always a friendly,
/// already-translated string from `ProductLookupFailure`, never a raw
/// exception.
class LookupErrorBanner extends StatelessWidget {
  const LookupErrorBanner({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wifiOff, size: 18, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySM.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child:
                TextButton(onPressed: onRetry, child: const Text('Try Again')),
          ),
        ],
      ),
    );
  }
}
