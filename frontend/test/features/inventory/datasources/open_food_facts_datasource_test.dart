import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:surfpos_ai/features/inventory/datasources/open_food_facts_datasource.dart';
import 'package:surfpos_ai/features/inventory/models/product_lookup_exception.dart';
import 'package:surfpos_ai/features/inventory/models/product_lookup_result.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _response(Map<String, dynamic> body) {
  return Response(
    data: body,
    statusCode: 200,
    requestOptions: RequestOptions(path: '/whatever'),
  );
}

void main() {
  late MockDio dio;
  late OpenFoodFactsDatasource datasource;

  setUp(() {
    dio = MockDio();
    datasource = OpenFoodFactsDatasource(dio: dio);
  });

  group('lookup() — mapping a found product', () {
    test('maps every Open Food Facts field to its ProductLookupResult field',
        () async {
      when(() => dio.get<dynamic>('/product/3017620422003.json')).thenAnswer(
        (_) async => _response({
          'code': '3017620422003',
          'status': 1,
          'product': {
            'code': '3017620422003',
            'product_name': 'Nutella',
            'brands': 'Ferrero, Ferrero SpA',
            'image_front_url': 'https://images.openfoodfacts.org/nutella.jpg',
            'quantity': '400 g',
            'categories': 'Spreads,Sweet spreads,Hazelnut spreads',
            'ingredients_text': 'Sugar, palm oil, hazelnuts 13%',
            'packaging': 'Glass jar',
            'countries': 'France,Germany',
            'nutriments': {
              'energy-kcal_100g': 539,
              'fat_100g': 30.9,
              'carbohydrates_100g': 57.5,
              'sugars_100g': 56.3,
              'proteins_100g': 6.3,
              'salt_100g': 0.107,
            },
          },
        }),
      );

      final result = await datasource.lookup('3017620422003');

      expect(result, isNotNull);
      expect(result!.barcode, '3017620422003');
      expect(result.name, 'Nutella');
      expect(result.brand, 'Ferrero, Ferrero SpA');
      expect(result.imageUrl, 'https://images.openfoodfacts.org/nutella.jpg');
      expect(result.weight, '400 g');
      expect(result.category, 'Spreads');
      expect(result.ingredients, 'Sugar, palm oil, hazelnuts 13%');
      expect(result.packaging, 'Glass jar');
      expect(result.country, 'France');
      expect(result.source, ProductLookupSource.openFoodFacts);
      expect(
        result.nutritionSummary,
        'Energy: 539 kcal, Fat: 30.9 g, Carbs: 57.5 g, Sugars: 56.3 g, '
        'Protein: 6.3 g, Salt: 0.107 g (per 100g)',
      );
    });

    test('stores the raw barcode exactly as returned by the provider',
        () async {
      when(() => dio.get<dynamic>('/product/0000000000000.json')).thenAnswer(
        (_) async => _response({
          'code': ' 0000000000000 ',
          'status': 1,
          'product': {'product_name': 'Mystery Item'},
        }),
      );

      final result = await datasource.lookup('0000000000000');

      expect(result!.barcode, '0000000000000');
    });

    test('tolerates a product with only a name — every other field is null',
        () async {
      when(() => dio.get<dynamic>('/product/1234567890128.json')).thenAnswer(
        (_) async => _response({
          'code': '1234567890128',
          'status': 1,
          'product': {'product_name': 'Bare Bones Product'},
        }),
      );

      final result = await datasource.lookup('1234567890128');

      expect(result!.name, 'Bare Bones Product');
      expect(result.brand, isNull);
      expect(result.imageUrl, isNull);
      expect(result.weight, isNull);
      expect(result.category, isNull);
      expect(result.ingredients, isNull);
      expect(result.nutritionSummary, isNull);
      expect(result.packaging, isNull);
      expect(result.country, isNull);
    });

    test('falls back to image_url when image_front_url is absent', () async {
      when(() => dio.get<dynamic>('/product/1234567890128.json')).thenAnswer(
        (_) async => _response({
          'code': '1234567890128',
          'status': 1,
          'product': {
            'product_name': 'Fallback Image Product',
            'image_url': 'https://images.openfoodfacts.org/fallback.jpg',
          },
        }),
      );

      final result = await datasource.lookup('1234567890128');

      expect(result!.imageUrl, 'https://images.openfoodfacts.org/fallback.jpg');
    });
  });

  group('lookup() — not found', () {
    test('returns null when status is 0 (no such product)', () async {
      when(() => dio.get<dynamic>('/product/9999999999999.json')).thenAnswer(
        (_) async => _response({
          'code': '9999999999999',
          'status': 0,
          'status_verbose': 'product not found',
        }),
      );

      final result = await datasource.lookup('9999999999999');

      expect(result, isNull);
    });
  });

  group('lookup() — error handling', () {
    test(
        'throws InvalidBarcodeException for a non-numeric code without any network call',
        () async {
      await expectLater(
        () => datasource.lookup('not-a-barcode'),
        throwsA(isA<InvalidBarcodeException>()),
      );
      verifyNever(() => dio.get<dynamic>(any()));
    });

    test('throws InvalidBarcodeException for a too-short code', () async {
      await expectLater(
        () => datasource.lookup('123'),
        throwsA(isA<InvalidBarcodeException>()),
      );
    });

    test('throws LookupTimeoutException on a connection timeout', () async {
      when(() => dio.get<dynamic>('/product/1234567890128.json')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/product/1234567890128.json'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await expectLater(
        () => datasource.lookup('1234567890128'),
        throwsA(isA<LookupTimeoutException>()),
      );
    });

    test('throws LookupNetworkException with no connectivity', () async {
      when(() => dio.get<dynamic>('/product/1234567890128.json')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/product/1234567890128.json'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        () => datasource.lookup('1234567890128'),
        throwsA(isA<LookupNetworkException>()),
      );
    });

    test('throws LookupUnknownException for an unexpected response body',
        () async {
      when(() => dio.get<dynamic>('/product/1234567890128.json'))
          .thenAnswer((_) async => Response(
                data: 'not a map',
                statusCode: 200,
                requestOptions: RequestOptions(path: '/whatever'),
              ));

      await expectLater(
        () => datasource.lookup('1234567890128'),
        throwsA(isA<LookupUnknownException>()),
      );
    });
  });
}
