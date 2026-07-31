import 'product_model.dart';

/// One page of `GET /inventory/products` — mirrors the backend's
/// `{ items, nextCursor }` cursor-pagination shape exactly (see
/// `backend/src/modules/inventory/product.repository.js`).
class InventoryPage {
  const InventoryPage({required this.items, required this.nextCursor});

  final List<ProductModel> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  factory InventoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['products'] as List<dynamic>? ?? [];
    return InventoryPage(
      items: rawItems
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
