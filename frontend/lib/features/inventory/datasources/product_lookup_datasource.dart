import '../models/product_lookup_result.dart';

/// One external product-database provider — Open Food Facts today, with
/// room for BarcodeLookup/UPCitemDB/etc. to be appended later without any
/// change to the UI or controller (see `ProductLookupRepository`, which
/// tries a list of these in order).
///
/// Responsibilities: call the provider, parse its response, and translate
/// any failure into a [ProductLookupException]. Never touches Inventory —
/// that merge (Inventory-first, then providers) is `ProductLookupRepository`
/// 's job, not any individual datasource's.
abstract class ProductLookupDatasource {
  /// Returns the parsed result, or `null` if this provider has no record for
  /// [barcode] (a clean "not found", not an error). Throws a
  /// `ProductLookupException` subtype for a real failure (network/timeout/
  /// invalid barcode/unexpected response).
  Future<ProductLookupResult?> lookup(String barcode);
}
