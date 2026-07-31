import '../models/inventory_page.dart';
import '../models/inventory_query.dart';
import '../models/product_draft.dart';
import '../models/product_model.dart';

/// Seam between the Riverpod controllers and the actual network calls —
/// lets Inventory's controllers be unit-tested against a fake, without
/// touching the real backend (see docs/07_CODING_RULES.md § 3), mirroring
/// `DashboardRepository`/`MerchantOnboardingRepository`.
abstract class InventoryRepository {
  /// `GET /inventory/products` — search/filter/sort/paginate.
  Future<InventoryPage> listProducts(InventoryQuery query,
      {String? cursor, int limit = 20});

  /// `GET /inventory/products/:id`.
  Future<ProductModel> getProduct(String productId);

  /// `POST /inventory/products`, then (only if [initialStock] is a positive
  /// quantity and [storeId] is given) `PATCH .../:id/stock` to set the
  /// opening stock count in one call from the caller's point of view.
  Future<ProductModel> createProduct(ProductDraft draft,
      {int? initialStock, String? storeId});

  /// `PATCH /inventory/products/:id`.
  Future<ProductModel> updateProduct(String productId, ProductDraft draft);

  /// `DELETE /inventory/products/:id` — soft delete.
  Future<void> deleteProduct(String productId);

  /// Adjusts stock at a specific store — `PATCH /inventory/products/:id/stock`.
  Future<void> adjustStock(String productId,
      {required String storeId, required int quantityDelta});

  /// Every distinct, non-empty category currently in use across the
  /// merchant's active catalog — derived client-side from a single bounded
  /// `listProducts` call (no dedicated backend endpoint exists for this;
  /// see docs/08_ARCHITECTURE_DECISIONS.md § ADR-024's documented
  /// small-catalog assumption). Good enough for the target retailer catalog
  /// size; revisit if catalogs grow past a single page.
  Future<List<String>> listCategories();

  /// Opens the OS photo gallery and returns the picked file's local path,
  /// or `null` if the user cancelled (not an error). Throws
  /// [ProductImageException] for permission-denied/missing-file/unexpected
  /// failures — see `docs/22_DEVELOPMENT_ROADMAP.md` (Product Image).
  Future<String?> pickImageFromGallery();

  /// Same contract as [pickImageFromGallery], via the device camera.
  Future<String?> captureImageFromCamera();
}
