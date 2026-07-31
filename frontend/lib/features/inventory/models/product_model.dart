import 'product_status.dart';

/// A single product in the merchant's catalog. Mirrors the `product` object
/// returned by every `/inventory/products` endpoint
/// (`backend/src/modules/inventory/inventory.service.js`) — field names here
/// are the friendly, UI-facing names; [fromJson]/[toCreateJson]/
/// [toUpdateJson] translate to/from the backend's wire field names
/// (`sellingPrice`→`price`, `taxRate`→`taxPercentage`,
/// `reorderLevel`→`lowStockThreshold`) so the rest of this feature never has
/// to think about that mapping.
///
/// `stockQuantity` is hydrated by the backend from a *separate* per-store
/// stock record (see `backend/src/modules/inventory/stock.repository.js`),
/// not stored on the product itself — every read still surfaces it as a
/// plain field here, so this model reads the same regardless of that
/// backend implementation detail.
///
/// [imagePath] is the same kind of client-only overlay, but local rather
/// than backend-hydrated: it's a device-local file path (see
/// `InventoryRepositoryImpl`'s `ProductImageLocalStorage`), never sent to or
/// read from the backend (which has no column for it) — cloud image storage
/// is a later phase. Deliberately distinct from [imageUrl] (a backend-owned,
/// full-URL field reserved for that future cloud image).
class ProductModel {
  const ProductModel({
    required this.id,
    this.merchantId,
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
    required this.stockQuantity,
    this.imageUrl,
    this.imagePath,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? merchantId;
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
  final int stockQuantity;
  final String? imageUrl;
  final String? imagePath;
  final ProductStatus status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isInStock => stockQuantity > 0;
  bool get isLowStock =>
      lowStockThreshold != null &&
      stockQuantity > 0 &&
      stockQuantity <= lowStockThreshold!;

  /// [imagePath] is never present in [json] (the backend doesn't know about
  /// it) — callers pass in whatever `ProductImageLocalStorage` has on file
  /// for this product's id, if anything.
  factory ProductModel.fromJson(Map<String, dynamic> json,
      {String? imagePath}) {
    return ProductModel(
      id: json['id'] as String,
      merchantId: json['merchantId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      category: json['category'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      price: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      taxPercentage: (json['taxRate'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (json['reorderLevel'] as num?)?.toInt(),
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      imagePath: imagePath,
      status: ProductStatus.fromWire(json['status'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num?)?.toInt() ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['updatedAt'] as num?)?.toInt() ?? 0),
    );
  }

  ProductModel copyWith({String? imagePath}) {
    return ProductModel(
      id: id,
      merchantId: merchantId,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      category: category,
      unit: unit,
      price: price,
      costPrice: costPrice,
      taxPercentage: taxPercentage,
      discountPercentage: discountPercentage,
      lowStockThreshold: lowStockThreshold,
      stockQuantity: stockQuantity,
      imageUrl: imageUrl,
      imagePath: imagePath ?? this.imagePath,
      status: status,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
