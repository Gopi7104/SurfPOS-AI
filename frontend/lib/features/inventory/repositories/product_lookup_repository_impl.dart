import '../datasources/product_lookup_datasource.dart';
import '../models/inventory_query.dart';
import 'inventory_repository.dart';
import 'product_lookup_repository.dart';

class ProductLookupRepositoryImpl implements ProductLookupRepository {
  ProductLookupRepositoryImpl({
    required InventoryRepository inventoryRepository,
    required List<ProductLookupDatasource> datasources,
  })  : _inventoryRepository = inventoryRepository,
        _datasources = datasources;

  final InventoryRepository _inventoryRepository;

  /// Tried in order; the first non-null result wins. Open Food Facts is
  /// first (free, no key) — appending another provider here is the only
  /// change needed to plug one in, no UI/controller change required.
  final List<ProductLookupDatasource> _datasources;

  @override
  Future<ProductLookupOutcome> lookup(String barcode) async {
    final page = await _inventoryRepository.listProducts(
      InventoryQuery(barcode: barcode),
      limit: 1,
    );
    if (page.items.isNotEmpty) {
      return ProductLookupExisting(page.items.first);
    }

    for (final datasource in _datasources) {
      final result = await datasource.lookup(barcode);
      if (result != null) return ProductLookupFound(result);
    }
    return const ProductLookupNotFound();
  }
}
