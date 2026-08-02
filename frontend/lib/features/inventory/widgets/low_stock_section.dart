import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../models/product_model.dart';
import 'stock_adjustment_sheet.dart';

/// Pinned warning section — products needing attention (low or out of
/// stock), from the same already-loaded catalog page the grid/list below
/// renders. Capped to a handful with a "+N more" hint (the full,
/// unbounded list is exactly what the Low Stock quick filter already
/// shows), each row offering a one-tap Quick Restock.
class LowStockSection extends StatelessWidget {
  const LowStockSection({
    required this.uid,
    required this.items,
    this.maxRows = 3,
    super.key,
  });

  final String uid;
  final List<ProductModel> items;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final needsAttention = items
        .where((p) => p.isOutOfStock || p.isLowStock)
        .toList(growable: false);
    if (needsAttention.isEmpty) return const SizedBox.shrink();

    final shown = needsAttention.take(maxRows).toList(growable: false);
    final remaining = needsAttention.length - shown.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.triangleAlert,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Text('Needs Attention',
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final product in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: _LowStockRow(uid: uid, product: product),
            ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('+$remaining more need attention',
                  style: AppTypography.caption),
            ),
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.uid, required this.product});

  final String uid;
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                  style: AppTypography.bodySM
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                product.isOutOfStock
                    ? 'Out of stock'
                    : '${product.stockQuantity} ${product.unit} left',
                style: AppTypography.caption.copyWith(
                    color: product.isOutOfStock
                        ? AppColors.error
                        : AppColors.warning),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => showStockAdjustmentSheet(context,
              uid: uid, product: product, allowNegative: false),
          style: OutlinedButton.styleFrom(
            // The app-wide OutlinedButtonTheme defaults to a full-width
            // `Size.fromHeight` minimum (every other OutlinedButton in this
            // app is meant to fill its row) — this is the one inline,
            // content-width button, so it needs its own explicit minimum.
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: AppColors.primary,
          ),
          child: const Text('Quick Restock'),
        ),
      ],
    );
  }
}
