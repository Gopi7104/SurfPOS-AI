import 'package:surfpos_ai/features/inventory/datasources/product_lookup_datasource.dart';
import 'package:surfpos_ai/features/inventory/models/product_lookup_result.dart';

/// Configurable [ProductLookupDatasource] test double — mirrors
/// `fake_inventory_repository.dart`'s shape: defaults to "no record", never
/// touching the real network, overridable per test via the constructor.
class FakeProductLookupDatasource implements ProductLookupDatasource {
  FakeProductLookupDatasource({
    Future<ProductLookupResult?> Function(String barcode)? lookup,
  }) : _lookup = lookup ?? ((barcode) async => null);

  final Future<ProductLookupResult?> Function(String barcode) _lookup;

  /// Every barcode this fake was actually asked to look up — lets tests
  /// assert a later provider in the chain was (or wasn't) reached.
  final List<String> calls = [];

  @override
  Future<ProductLookupResult?> lookup(String barcode) {
    calls.add(barcode);
    return _lookup(barcode);
  }
}

ProductLookupResult testLookupResult({
  String barcode = '3017620422003',
  String? name = 'Nutella',
  String? brand = 'Ferrero',
  String? imageUrl,
  String? weight = '400 g',
  String? category = 'Spreads',
  String? ingredients,
  String? nutritionSummary,
  String? packaging,
  String? country,
  ProductLookupSource source = ProductLookupSource.openFoodFacts,
}) {
  return ProductLookupResult(
    barcode: barcode,
    name: name,
    brand: brand,
    imageUrl: imageUrl,
    weight: weight,
    category: category,
    ingredients: ingredients,
    nutritionSummary: nutritionSummary,
    packaging: packaging,
    country: country,
    source: source,
  );
}
