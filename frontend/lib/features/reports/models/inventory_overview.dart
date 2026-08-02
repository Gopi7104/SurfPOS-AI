/// Inventory Overview section KPIs — Products/Low Stock/Out of Stock/
/// Categories. Unlike every other Reports section, this one has a real,
/// live data source ([ReportsRepositoryImpl] reads it straight from
/// `InventoryRepository`, mirroring `inventoryStatsProvider`'s own bounded-
/// sample approach) since stock levels already exist regardless of whether
/// any sale has ever been recorded.
class InventoryOverview {
  const InventoryOverview({
    required this.productsCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.categoriesCount,
    required this.isApproximate,
  });

  final int productsCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int categoriesCount;

  /// True when the catalog is larger than the bounded sample this was
  /// computed from — see `inventoryStatsProvider`'s own documented
  /// small-catalog assumption (docs/08_ARCHITECTURE_DECISIONS.md § ADR-024).
  final bool isApproximate;

  factory InventoryOverview.empty() => const InventoryOverview(
        productsCount: 0,
        lowStockCount: 0,
        outOfStockCount: 0,
        categoriesCount: 0,
        isApproximate: false,
      );
}
