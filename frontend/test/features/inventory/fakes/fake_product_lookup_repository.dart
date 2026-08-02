import 'package:surfpos_ai/features/inventory/repositories/product_lookup_repository.dart';

/// Configurable [ProductLookupRepository] test double — mirrors
/// `fake_billing_repository.dart`'s shape: overridable per test via the
/// constructor, never touching the real network or Inventory.
class FakeProductLookupRepository implements ProductLookupRepository {
  FakeProductLookupRepository({
    Future<ProductLookupOutcome> Function(String barcode)? lookup,
  }) : _lookup = lookup ?? ((barcode) async => const ProductLookupNotFound());

  final Future<ProductLookupOutcome> Function(String barcode) _lookup;

  @override
  Future<ProductLookupOutcome> lookup(String barcode) => _lookup(barcode);
}
