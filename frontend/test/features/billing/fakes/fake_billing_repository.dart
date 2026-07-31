import 'package:surfpos_ai/features/billing/repositories/billing_repository.dart';
import 'package:surfpos_ai/features/inventory/models/product_model.dart';
import 'package:surfpos_ai/features/inventory/models/product_status.dart';

/// Configurable [BillingRepository] test double — mirrors
/// `fake_inventory_repository.dart`'s shape: every method defaults to a
/// no-op/empty behavior, overridable per test via the constructor, never
/// touching the real network.
class FakeBillingRepository implements BillingRepository {
  FakeBillingRepository({
    Future<List<ProductModel>> Function(String query, {int limit})?
        searchProducts,
    Future<ProductModel?> Function(String barcode)? findProductByBarcode,
  })  : _searchProducts =
            searchProducts ?? ((query, {limit = 10}) async => const []),
        _findProductByBarcode =
            findProductByBarcode ?? ((barcode) async => null);

  final Future<List<ProductModel>> Function(String query, {int limit})
      _searchProducts;
  final Future<ProductModel?> Function(String barcode) _findProductByBarcode;

  @override
  Future<List<ProductModel>> searchProducts(String query, {int limit = 10}) =>
      _searchProducts(query, limit: limit);

  @override
  Future<ProductModel?> findProductByBarcode(String barcode) =>
      _findProductByBarcode(barcode);
}

/// A product fixture with non-zero tax/discount (unlike Inventory's own
/// `testProduct()`, which hardcodes both to 0) — Billing's cart-calculation
/// tests need real percentages to exercise `CartItemModel`'s getters.
ProductModel testCartProduct({
  String id = 'prod-1',
  String name = 'Blue Wave Surf Wax',
  String sku = 'WAX-01',
  String? barcode,
  double price = 100,
  double taxPercentage = 10,
  double discountPercentage = 0,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return ProductModel(
    id: id,
    merchantId: 'm-1',
    name: name,
    sku: sku,
    barcode: barcode,
    unit: 'pcs',
    price: price,
    costPrice: price / 2,
    taxPercentage: taxPercentage,
    discountPercentage: discountPercentage,
    stockQuantity: 25,
    status: ProductStatus.active,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
