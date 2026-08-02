/// Where a [ProductLookupResult] came from — the merchant's own Inventory
/// (already imported once, no network call made) or an external product
/// database provider (Open Food Facts today; more can be added later
/// without any UI change — see `ProductLookupRepository`).
enum ProductLookupSource { inventory, openFoodFacts }

/// A barcode scan's resolved product information, ahead of the merchant
/// creating/reviewing the actual [ProductDraft] — deliberately a separate
/// model rather than a partial [ProductModel]/[ProductDraft]: this only
/// carries what a public product database can tell us (name, brand, image,
/// weight, category, ingredients, nutrition, packaging, country), never the
/// store-specific fields (price, cost, stock, tax, SKU) a merchant must
/// always enter themselves.
class ProductLookupResult {
  const ProductLookupResult({
    required this.barcode,
    this.name,
    this.brand,
    this.imageUrl,
    this.weight,
    this.category,
    this.ingredients,
    this.nutritionSummary,
    this.packaging,
    this.country,
    this.source = ProductLookupSource.openFoodFacts,
  });

  /// The raw barcode exactly as scanned/returned — never reformatted.
  final String barcode;
  final String? name;
  final String? brand;
  final String? imageUrl;

  /// Net weight/quantity as the provider reports it (e.g. "400 g", "1 L") —
  /// free text, since units vary by provider and product type.
  final String? weight;
  final String? category;
  final String? ingredients;

  /// A short, human-readable nutrition line (e.g. "Energy: 539 kcal, Fat:
  /// 30.9 g, ... (per 100g)") — not the provider's raw nutriment map, so the
  /// UI never has to know that shape.
  final String? nutritionSummary;
  final String? packaging;
  final String? country;
  final ProductLookupSource source;
}
