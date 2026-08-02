import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Shown when a scanned barcode matches no record in the merchant's
/// Inventory *or* any external product database — "IF PRODUCT IS NOT
/// FOUND": copy is exactly "Product not found in product database.",
/// offering "Enter Manually" (the barcode stays filled in) or "Try Again".
/// Purely presentational, mirrors `ProductNotFoundBanner`'s shape.
class LookupNotFoundBanner extends StatelessWidget {
  const LookupNotFoundBanner({
    required this.barcode,
    required this.onEnterManually,
    required this.onTryAgain,
    super.key,
  });

  final String barcode;
  final VoidCallback onEnterManually;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.searchX,
                  size: 18, color: AppColors.textGrey),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Product not found in product database.',
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Barcode $barcode — you can still add it, just fill in the details.',
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: onTryAgain, child: const Text('Try Again')),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                    onPressed: onEnterManually,
                    child: const Text('Enter Manually')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
