import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/product_model.dart';
import '../models/product_status.dart';
import 'product_thumbnail.dart';

/// One product row in Inventory's **list** view — thumbnail, name, SKU,
/// price, stock, category, a [StatusChip] for [ProductModel.status], and a
/// low-stock/out-of-stock badge when applicable. Tapping opens Product
/// Details; long-pressing surfaces Quick Actions. (`ProductGridCard` is the
/// grid-view sibling, both feeding off the same `InventoryHomePage` data.)
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  StatusTone get _statusTone => product.status == ProductStatus.active
      ? StatusTone.success
      : StatusTone.neutral;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: GestureDetector(
        onLongPress: onLongPress,
        behavior: HitTestBehavior.translucent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumbnail(product: product, size: 52),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.bodyLG
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        'SKU: ${product.sku}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textGrey),
                      ),
                      if (product.barcode != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(LucideIcons.scanLine,
                            size: 12, color: AppColors.textGrey),
                      ],
                    ],
                  ),
                  if (product.category != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.category!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textGrey),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      StatusChip(
                          label: product.status.label, tone: _statusTone),
                      if (product.isOutOfStock)
                        const StatusChip(
                            label: 'Out of Stock', tone: StatusTone.error)
                      else if (product.isLowStock)
                        const StatusChip(
                            label: 'Low Stock', tone: StatusTone.warning),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: AppTypography.bodyLG.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${product.stockQuantity} ${product.unit}',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.textGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
