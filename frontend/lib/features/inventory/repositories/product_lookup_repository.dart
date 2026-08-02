import '../models/product_lookup_result.dart';
import '../models/product_model.dart';

/// One outcome of [ProductLookupRepository.lookup] — deliberately not a
/// nullable [ProductLookupResult] alone: "already in this merchant's
/// Inventory" and "found via an external provider" need different UI
/// treatment (the former should offer to view/restock the existing
/// product, never a duplicate-add form), and "not found anywhere" needs a
/// third, distinct treatment again.
sealed class ProductLookupOutcome {
  const ProductLookupOutcome();
}

/// The barcode already belongs to a product in this merchant's Inventory —
/// no external provider was called (see "CACHE": a barcode already imported
/// once must never re-hit Open Food Facts).
class ProductLookupExisting extends ProductLookupOutcome {
  const ProductLookupExisting(this.product);

  final ProductModel product;
}

/// An external provider (Open Food Facts, or a future one) had a record for
/// this barcode.
class ProductLookupFound extends ProductLookupOutcome {
  const ProductLookupFound(this.result);

  final ProductLookupResult result;
}

/// Neither this merchant's Inventory nor any configured provider has a
/// record for this barcode.
class ProductLookupNotFound extends ProductLookupOutcome {
  const ProductLookupNotFound();
}

/// Seam between [ProductLookupController] and barcode-to-product
/// resolution — merges the merchant's own Inventory (checked first, no
/// network call) with external product-database providers (Open Food Facts
/// today; more can be appended without any UI change). Deliberately never
/// used by Billing — Billing resolves scanned barcodes purely against
/// Inventory via `BillingRepository`, on purpose (no internet lookup during
/// Billing).
abstract class ProductLookupRepository {
  Future<ProductLookupOutcome> lookup(String barcode);
}
