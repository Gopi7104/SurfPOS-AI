/// One fake product in a generated demo catalog — presentation-only, never
/// written to the real `InventoryRepository`/backend (see
/// `DemoDataGenerator`'s header comment for why this is a fully separate,
/// local-only model rather than a real `ProductModel`).
class DemoProduct {
  const DemoProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.costPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.unitsSold,
    required this.colorSeed,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double costPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final int unitsSold;

  /// Deterministic seed for a placeholder color swatch (no real product
  /// photo exists for demo data) — kept stable across rebuilds/persistence.
  final int colorSeed;

  double get revenue => price * unitsSold;
  bool get isLowStock => stockQuantity <= lowStockThreshold;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'costPrice': costPrice,
        'stockQuantity': stockQuantity,
        'lowStockThreshold': lowStockThreshold,
        'unitsSold': unitsSold,
        'colorSeed': colorSeed,
      };

  factory DemoProduct.fromJson(Map<String, dynamic> json) => DemoProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        costPrice: (json['costPrice'] as num).toDouble(),
        stockQuantity: json['stockQuantity'] as int,
        lowStockThreshold: json['lowStockThreshold'] as int,
        unitsSold: json['unitsSold'] as int,
        colorSeed: json['colorSeed'] as int,
      );
}
