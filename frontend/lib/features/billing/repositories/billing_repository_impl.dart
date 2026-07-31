import '../../inventory/models/inventory_query.dart';
import '../../inventory/models/product_model.dart';
import '../../inventory/repositories/inventory_repository.dart';
import 'billing_repository.dart';

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl({required InventoryRepository inventoryRepository})
      : _inventoryRepository = inventoryRepository;

  final InventoryRepository _inventoryRepository;

  @override
  Future<List<ProductModel>> searchProducts(String query,
      {int limit = 10}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final page = await _inventoryRepository.listProducts(
      InventoryQuery(search: trimmed),
      limit: limit,
    );
    return page.items;
  }

  @override
  Future<ProductModel?> findProductByBarcode(String barcode) async {
    final page = await _inventoryRepository.listProducts(
      InventoryQuery(barcode: barcode),
      limit: 1,
    );
    return page.items.isEmpty ? null : page.items.first;
  }
}
