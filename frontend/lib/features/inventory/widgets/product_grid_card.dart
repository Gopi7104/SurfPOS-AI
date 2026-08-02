import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/product_model.dart';

/// One product tile in Inventory's grid view — large image, name,
/// category, price, current stock, a barcode indicator when the product
/// has one, and a low/out-of-stock badge. Tapping opens Product Details;
/// long-pressing surfaces the Quick Actions sheet — this widget owns no
/// business logic, purely renders [product] and reports gestures (see
/// `CartItemTile`'s header comment in the Billing feature for the same
/// convention).
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

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.curve.standard,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: AppTypography.numberSM
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                        if (product.barcode != null)
                          const Icon(LucideIcons.scanLine,
                              size: 14, color: AppColors.textGrey),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.stockQuantity} ${product.unit}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
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
      aspectRatio: 1.15,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.primarySubtle, child: _image()),
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

  Widget _image() {
    final path = product.imagePath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _PlaceholderIcon(),
        );
      }
    }
    final url = product.imageUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _PlaceholderIcon(),
      );
    }
    return const _PlaceholderIcon();
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(LucideIcons.package, size: 36, color: AppColors.primary),
    );
  }
}
