import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../controllers/inventory_form_controller.dart';
import '../controllers/inventory_list_controller.dart';
import '../controllers/product_lookup_controller.dart';
import '../datasources/open_food_facts_datasource.dart';
import '../models/inventory_query.dart';
import '../models/product_lookup_state.dart';
import '../models/product_model.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/inventory_repository_impl.dart';
import '../repositories/product_image_local_storage.dart';
import '../repositories/product_lookup_repository.dart';
import '../repositories/product_lookup_repository_impl.dart';

/// One product's live details — keyed by (uid, productId) rather than just
/// productId, staying consistent with "every provider tied to the
/// authenticated uid" even though ownership is also enforced server-side.
typedef ProductDetailsKey = ({String uid, String productId});

/// Product Image's local-only persistence (see [ProductImageLocalStorage])
/// — reuses the authentication feature's shared [secureStorageServiceProvider]
/// exactly like `merchantOnboardingLocalStorageProvider` does, rather than
/// redeclaring a second `SecureStorageService`.
final productImageLocalStorageProvider =
    Provider<ProductImageLocalStorage>((ref) {
  return ProductImageLocalStorage(ref.watch(secureStorageServiceProvider));
});

/// DI wiring for the Inventory feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3), reusing the
/// authentication feature's shared [apiClientProvider] exactly like
/// `dashboard/providers/dashboard_providers.dart` does.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    imageLocalStorage: ref.watch(productImageLocalStorageProvider),
  );
});

/// Keyed by Firebase uid (see docs/22_DEVELOPMENT_ROADMAP.md, cross-user
/// isolation fix) — never a global singleton. A different signed-in account
/// gets a completely separate list/cache instance; `autoDispose` frees a
/// previous user's loaded products the moment nothing watches it anymore.
final inventoryListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<InventoryListController, InventoryListState, String>(
  InventoryListController.new,
);

/// DI wiring for barcode-onboarding lookups — Open Food Facts is first (and
/// today, the only) provider in the chain; appending another
/// `ProductLookupDatasource` here is the only change needed to plug one in.
final productLookupRepositoryProvider =
    Provider<ProductLookupRepository>((ref) {
  return ProductLookupRepositoryImpl(
    inventoryRepository: ref.watch(inventoryRepositoryProvider),
    datasources: [OpenFoodFactsDatasource()],
  );
});

/// Keyed by Firebase uid, same cross-user-isolation reason as every other
/// controller in this app.
final productLookupControllerProvider = NotifierProvider.autoDispose
    .family<ProductLookupController, ProductLookupState, String>(
  ProductLookupController.new,
);

/// One-shot create/update form state for a single Add/Edit Product screen —
/// still keyed by uid for the same cross-user-isolation reason as every
/// other controller in this app, even though its state is short-lived.
final inventoryFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<InventoryFormController, ProductModel?, String>(
  InventoryFormController.new,
);

/// Distinct categories currently in use — powers the Categories page and
/// the Product List's category filter. `autoDispose` (not `keepAlive`) so a
/// stale category list never survives a account switch, consistent with
/// every other uid-scoped provider in this app.
final inventoryCategoriesProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, uid) {
  return ref.watch(inventoryRepositoryProvider).listCategories();
});

/// `GET /inventory/products/:id` for Product Details — `autoDispose` so a
/// stale product never survives navigating away and back.
final productDetailsProvider = FutureProvider.autoDispose
    .family<ProductModel, ProductDetailsKey>((ref, key) {
  return ref.watch(inventoryRepositoryProvider).getProduct(key.productId);
});

/// Inventory Home's summary counts. Derived from a single bounded fetch (up
/// to 100 active products) rather than a dedicated backend stats endpoint —
/// [InventoryStats.isApproximate] is true when the catalog is larger than
/// that sample, in which case [totalProducts] undercounts (shown as "100+"
/// by the UI) but [lowStockCount]/[outOfStockCount] would too; acceptable
/// for the target small-retailer catalog size (see
/// docs/08_ARCHITECTURE_DECISIONS.md § ADR-024's documented assumption).
typedef InventoryStats = ({
  int totalProducts,
  int lowStockCount,
  int outOfStockCount,
  bool isApproximate
});

const _statsSampleLimit = 100;

final inventoryStatsProvider =
    FutureProvider.autoDispose.family<InventoryStats, String>((ref, uid) async {
  final page = await ref
      .watch(inventoryRepositoryProvider)
      .listProducts(const InventoryQuery(), limit: _statsSampleLimit);
  return (
    totalProducts: page.items.length,
    lowStockCount: page.items.where((product) => product.isLowStock).length,
    outOfStockCount: page.items.where((product) => product.isOutOfStock).length,
    isApproximate: page.hasMore,
  );
});
