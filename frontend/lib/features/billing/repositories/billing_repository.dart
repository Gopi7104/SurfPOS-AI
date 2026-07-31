import '../../inventory/models/product_model.dart';

/// Seam between [BillingController] and product lookup — deliberately thin:
/// Billing never talks to `InventoryRepository` directly, and never
/// re-implements Inventory's search/filter logic (see
/// docs/22_DEVELOPMENT_ROADMAP.md, Phase 3: "Do not duplicate Inventory
/// logic. Reuse InventoryRepository."). Both methods exist purely to
/// compose `InventoryRepository.listProducts` differently — fuzzy search
/// for manual entry, exact match for a scanned code.
abstract class BillingRepository {
  /// Product-name/SKU/barcode substring search for the search bar's
  /// suggestions — delegates to Inventory's existing fuzzy `search` query
  /// param. Returns an empty list for a blank query, never all products.
  Future<List<ProductModel>> searchProducts(String query, {int limit = 10});

  /// Exact-match barcode lookup for the scanner flow — `null` if no active
  /// product in the merchant's catalog has this exact barcode.
  Future<ProductModel?> findProductByBarcode(String barcode);
}
