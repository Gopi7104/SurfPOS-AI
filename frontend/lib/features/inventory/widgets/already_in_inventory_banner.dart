import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/product_model.dart';

/// Shown when a scanned barcode already belongs to a product in this
/// merchant's own Inventory (see "CACHE": a barcode already imported once
/// must never re-hit Open Food Facts, and must never silently create a
/// duplicate catalog entry either) — offers to view the existing product or
/// scan a different one.
class AlreadyInInventoryBanner extends StatelessWidget {
  const AlreadyInInventoryBanner({
    required this.product,
    required this.onViewProduct,
    required this.onScanAgain,
    super.key,
  });

  final ProductModel product;
  final VoidCallback onViewProduct;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.badgeCheck,
                  size: 18, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Already in your inventory',
                  style: AppTypography.bodyMD.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            product.name,
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: onScanAgain, child: const Text('Scan Again')),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                    onPressed: onViewProduct,
                    child: const Text('View Product')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
