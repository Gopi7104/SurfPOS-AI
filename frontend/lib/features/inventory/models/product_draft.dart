import 'product_status.dart';

/// The Add/Edit Product form's validated output — every field
/// `createProductSchema`/`updateProductSchema` accept, in the same
/// friendly field names as [ProductModel]. Kept separate from
/// [ProductModel] (rather than reusing it with placeholder id/timestamps)
/// because a draft has no id/merchantId/stock/timestamps yet — those are
/// server-assigned or read from a separate stock record, never something a
/// form fills in directly.
class ProductDraft {
  const ProductDraft({
    required this.name,
    this.description,
    required this.sku,
    this.barcode,
    this.category,
    required this.unit,
    required this.price,
    required this.costPrice,
    required this.taxPercentage,
    required this.discountPercentage,
    this.lowStockThreshold,
    this.imageUrl,
    this.imagePath,
    this.status = ProductStatus.active,
  });

  final String name;
  final String? description;
  final String sku;
  final String? barcode;
  final String? category;
  final String unit;
  final double price;
  final double costPrice;
  final double taxPercentage;
  final double discountPercentage;
  final int? lowStockThreshold;
  final String? imageUrl;

  /// Local device file path for the product's photo (Product Image feature)
  /// — client-only, deliberately **not** included in [toJson]: the backend
  /// has no field for it (no cloud upload yet). Persisted separately by
  /// `InventoryRepositoryImpl` via `ProductImageLocalStorage`, keyed by the
  /// product's id once one exists.
  final String? imagePath;
  final ProductStatus status;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'sku': sku,
        if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
        if (category != null && category!.isNotEmpty) 'category': category,
        'unit': unit,
        'costPrice': costPrice,
        'sellingPrice': price,
        'taxRate': taxPercentage,
        'discountPercentage': discountPercentage,
        if (lowStockThreshold != null) 'reorderLevel': lowStockThreshold,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        'status': status.wireValue,
      };
}
