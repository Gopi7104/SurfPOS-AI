import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';

/// Shown when a scanned/looked-up barcode matches no active product (see
/// docs/22_DEVELOPMENT_ROADMAP.md, Phase 3: "IF PRODUCT NOT FOUND — Show
/// 'Product not found.' Offer Search manually or Add Product"). Purely
/// presentational — [onSearchManually]/[onAddProduct]/[onDismiss] are
/// supplied by the page, which owns the actual navigation/focus behavior.
class ProductNotFoundBanner extends StatelessWidget {
  const ProductNotFoundBanner({
    required this.barcode,
    required this.onSearchManually,
    required this.onAddProduct,
    required this.onDismiss,
    super.key,
  });

  final String barcode;
  final VoidCallback onSearchManually;
  final VoidCallback onAddProduct;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
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
              const Icon(LucideIcons.circleAlert,
                  size: 18, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Product not found.',
                  style: AppTypography.bodyMD.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(LucideIcons.x, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No product with barcode "$barcode" was found in your catalog.',
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton(
                  onPressed: onSearchManually,
                  child: const Text('Search Manually')),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                  onPressed: onAddProduct, child: const Text('Add Product')),
            ],
          ),
        ],
      ),
    );
  }
}
