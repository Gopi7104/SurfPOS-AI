import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../models/product_model.dart';

/// A product's image — local [ProductModel.imagePath] first, then the
/// backend-owned [ProductModel.imageUrl], then a package-icon placeholder.
/// Shared by `ProductCard` (list view) and `ProductGridCard` (grid view) so
/// both read the same image the same way.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.product,
    this.size = 48,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  final ProductModel product;

  /// `null` fills whatever space the parent already constrains (e.g. a
  /// `Stack` with `StackFit.expand`) instead of forcing a fixed box.
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.primarySubtle,
        child: _image(),
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
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      }
    }
    final url = product.imageUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Icon(LucideIcons.package,
          size: (size ?? 64) * 0.45, color: AppColors.primary),
    );
  }
}
