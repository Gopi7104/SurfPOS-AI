import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../inventory/models/product_model.dart';
import 'product_thumbnail.dart';

/// One product tile in Billing's product grid — image (or a placeholder),
/// name, category, price, and a low/out-of-stock badge. Tapping adds it to
/// the cart (disabled while out of stock); long-pressing surfaces a
/// quick-actions callback (Billing wires this to Inventory's existing
/// Product Details screen) — this widget owns no business logic, purely
/// renders [product] and reports gestures, matching every other tile in
/// this feature (see `CartItemTile`'s own header comment).
class ProductGridCard extends StatefulWidget {
  const ProductGridCard({
    required this.product,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<ProductGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final outOfStock = product.isOutOfStock;

    return GestureDetector(
      onTap: outOfStock ? null : widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: outOfStock ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.curve.standard,
        child: Opacity(
          opacity: outOfStock ? 0.55 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Thumbnail(product: product),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTypography.bodySM
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.category!,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: AppTypography.numberSM
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductThumbnail(product: product, size: null, borderRadius: 0),
          if (product.isOutOfStock)
            const Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: StatusChip(label: 'Out of Stock', tone: StatusTone.error),
            )
          else if (product.isLowStock)
            const Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: StatusChip(label: 'Low Stock', tone: StatusTone.warning),
            ),
        ],
      ),
    );
  }
}
