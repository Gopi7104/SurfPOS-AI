import 'package:dio/dio.dart';

import '../models/product_lookup_exception.dart';
import '../models/product_lookup_result.dart';
import 'product_lookup_datasource.dart';

/// Open Food Facts' free, keyless public product database —
/// https://world.openfoodfacts.org/api/v2/product/{barcode}.json.
///
/// Deliberately uses its own [Dio] instance rather than the app's shared
/// `ApiClient`: Open Food Facts is a third-party API with its own base URL
/// and response envelope (`{code, product, status}`) — nothing like this
/// app's own backend `{success, data}` shape `ApiClient` unwraps — so
/// reusing it would mean bending that client to a shape it was never meant
/// to parse.
class OpenFoodFactsDatasource implements ProductLookupDatasource {
  OpenFoodFactsDatasource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://world.openfoodfacts.org/api/v2',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  final Dio _dio;

  /// EAN-8/EAN-13/UPC-A/UPC-E/GTIN-14 are all-digit, 6-14 characters —
  /// anything outside that shape can't be a retail barcode Open Food Facts
  /// would index, so it's rejected before spending a network call on it.
  static final RegExp _barcodePattern = RegExp(r'^[0-9]{6,14}$');

  @override
  Future<ProductLookupResult?> lookup(String barcode) async {
    final trimmed = barcode.trim();
    if (!_barcodePattern.hasMatch(trimmed)) {
      throw const InvalidBarcodeException();
    }

    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>('/product/$trimmed.json');
    } on DioException catch (error) {
      throw _mapError(error);
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const LookupUnknownException();
    }
    // Open Food Facts answers with HTTP 200 either way — `status` (not the
    // HTTP status code) is 1 for "found", 0 for "no such product".
    if (body['status'] != 1) return null;

    final product = body['product'];
    if (product is! Map<String, dynamic>) return null;

    final rawCode = _stringOrNull(body['code']) ??
        _stringOrNull(product['code']) ??
        trimmed;
    return _mapProduct(rawCode, product);
  }

  ProductLookupException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const LookupTimeoutException();
      case DioExceptionType.connectionError:
        return const LookupNetworkException();
      default:
        if (error.response == null) return const LookupNetworkException();
        return const LookupUnknownException();
    }
  }

  ProductLookupResult _mapProduct(
      String barcode, Map<String, dynamic> product) {
    return ProductLookupResult(
      barcode: barcode,
      name: _stringOrNull(product['product_name']),
      brand: _stringOrNull(product['brands']),
      imageUrl: _stringOrNull(product['image_front_url']) ??
          _stringOrNull(product['image_url']),
      weight: _stringOrNull(product['quantity']),
      category: _firstOf(product['categories']),
      ingredients: _stringOrNull(product['ingredients_text']),
      nutritionSummary: _nutritionSummary(product['nutriments']),
      packaging: _stringOrNull(product['packaging']),
      country: _firstOf(product['countries']),
      source: ProductLookupSource.openFoodFacts,
    );
  }

  String? _stringOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Open Food Facts' `categories`/`countries` fields are human-readable,
  /// comma-separated lists (e.g. "Spreads,Sweet spreads,Hazelnut spreads") —
  /// the first entry is the most general/reliable one to prefill.
  String? _firstOf(Object? commaSeparated) {
    final value = _stringOrNull(commaSeparated);
    if (value == null) return null;
    final first = value.split(',').first.trim();
    return first.isEmpty ? null : first;
  }

  String? _nutritionSummary(Object? nutriments) {
    if (nutriments is! Map) return null;
    final parts = <String>[];
    void add(String label, String key, String unit) {
      final value = nutriments['${key}_100g'];
      if (value is num) parts.add('$label: $value$unit');
    }

    add('Energy', 'energy-kcal', ' kcal');
    add('Fat', 'fat', ' g');
    add('Carbs', 'carbohydrates', ' g');
    add('Sugars', 'sugars', ' g');
    add('Protein', 'proteins', ' g');
    add('Salt', 'salt', ' g');

    if (parts.isEmpty) return null;
    return '${parts.join(', ')} (per 100g)';
  }
}
