/// One row in the Top Selling Products section.
class TopProduct {
  const TopProduct({
    required this.productId,
    required this.name,
    required this.sku,
    this.imageUrl,
    this.imagePath,
    required this.unitsSold,
    required this.revenue,
    required this.progress,
  });

  final String productId;
  final String name;
  final String sku;
  final String? imageUrl;
  final String? imagePath;
  final int unitsSold;
  final double revenue;

  /// Units sold relative to the top seller in this list, `0.0`–`1.0` — the
  /// progress bar's fill fraction. `1.0` for whichever product has the
  /// most units sold, `0.0` when every product in the list has zero sales
  /// (nothing to compare against yet).
  final double progress;
}
