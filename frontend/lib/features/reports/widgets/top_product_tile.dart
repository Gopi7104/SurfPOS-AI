import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../models/top_product.dart';

/// One row in the Top Selling Products list — image (or a placeholder),
/// name/SKU, units sold/revenue, and a progress bar showing units sold
/// relative to the list's top seller.
class TopProductTile extends StatelessWidget {
  const TopProductTile({required this.product, super.key});

  final TopProduct product;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          _Thumbnail(imagePath: product.imagePath, imageUrl: product.imageUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('SKU: ${product.sku}', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: product.progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.disabledSurface,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${product.revenue.toStringAsFixed(2)}',
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${product.unitsSold} sold', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.imagePath, this.imageUrl});

  final String? imagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 44,
        height: 44,
        color: AppColors.primarySubtle,
        child: _image() ??
            const Icon(LucideIcons.package, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget? _image() {
    final path = imagePath;
    if (path != null) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    final url = imageUrl;
    if (url != null) {
      return Image.network(url, fit: BoxFit.cover);
    }
    return null;
  }
}
