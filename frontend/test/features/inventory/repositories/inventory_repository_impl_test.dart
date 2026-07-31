import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:surfpos_ai/core/network/api_client.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_query.dart';
import 'package:surfpos_ai/features/inventory/models/product_draft.dart';
import 'package:surfpos_ai/features/inventory/models/product_image_exception.dart';
import 'package:surfpos_ai/features/inventory/repositories/inventory_repository_impl.dart';
import 'package:surfpos_ai/features/inventory/repositories/product_image_local_storage.dart';

class MockDio extends Mock implements Dio {}

class MockImagePicker extends Mock implements ImagePicker {}

/// In-memory [SecureStorageService] double — no platform channel involved,
/// mirroring `merchant_onboarding_local_storage_test.dart`'s fake.
class _FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

Response<dynamic> _response(Map<String, dynamic> body) {
  return Response(
      data: body,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/whatever'));
}

Map<String, dynamic> _productJson({
  String id = 'prod-1',
  String sku = 'WAX-01',
  int stockQuantity = 10,
}) {
  return {
    'id': id,
    'merchantId': 'm-1',
    'name': 'Wax',
    'sku': sku,
    'unit': 'pcs',
    'sellingPrice': 19.99,
    'costPrice': 9.99,
    'taxRate': 0,
    'discountPercentage': 0,
    'reorderLevel': 5,
    'stockQuantity': stockQuantity,
    'status': 'ACTIVE',
    'isActive': true,
    'createdAt': 1,
    'updatedAt': 1,
  };
}

const _validDraft = ProductDraft(
  name: 'Wax',
  sku: 'WAX-01',
  unit: 'pcs',
  price: 19.99,
  costPrice: 9.99,
  taxPercentage: 0,
  discountPercentage: 0,
);

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  late MockDio dio;
  late ApiClient apiClient;
  late MockImagePicker imagePicker;
  late InventoryRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    apiClient = ApiClient(dio: dio, baseUrl: 'http://localhost:4000');
    imagePicker = MockImagePicker();
    repository = InventoryRepositoryImpl(
      apiClient: apiClient,
      imageLocalStorage: ProductImageLocalStorage(_FakeSecureStorageService()),
      imagePicker: imagePicker,
    );
  });

  test('listProducts() sends the query as query parameters and parses the page',
      () async {
    when(() => dio.get('/inventory/products',
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'))).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {
          'products': [_productJson()],
          'nextCursor': 'prod-1',
        },
      }),
    );

    final page = await repository
        .listProducts(const InventoryQuery(search: 'wax'), limit: 20);

    expect(page.items, hasLength(1));
    expect(page.items.first.sku, 'WAX-01');
    expect(page.nextCursor, 'prod-1');
    final captured = verify(() => dio.get(
          '/inventory/products',
          queryParameters: captureAny(named: 'queryParameters'),
          options: any(named: 'options'),
        )).captured;
    expect(captured.single, {'search': 'wax', 'limit': 20});
  });

  test(
      'createProduct() posts the draft and does not adjust stock when initialStock is omitted',
      () async {
    when(() => dio.post('/inventory/products',
            data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => _response({
              'success': true,
              'data': {'product': _productJson()}
            }));

    final product = await repository.createProduct(_validDraft);

    expect(product.sku, 'WAX-01');
    verifyNever(() => dio.patch(any(),
        data: any(named: 'data'), options: any(named: 'options')));
  });

  test(
      'createProduct() adjusts stock and re-fetches when initialStock + storeId are given',
      () async {
    when(() => dio.post('/inventory/products',
            data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => _response({
              'success': true,
              'data': {'product': _productJson(stockQuantity: 0)}
            }));
    when(() => dio.patch('/inventory/products/prod-1/stock',
            data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => _response({
              'success': true,
              'data': {'stock': {}}
            }));
    when(() => dio.get('/inventory/products/prod-1',
        options: any(named: 'options'))).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {'product': _productJson(stockQuantity: 15)}
      }),
    );

    final product = await repository.createProduct(_validDraft,
        initialStock: 15, storeId: 'store-1');

    expect(product.stockQuantity, 15);
    final captured = verify(() => dio.patch(
          '/inventory/products/prod-1/stock',
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        )).captured;
    expect(captured.single, {'storeId': 'store-1', 'quantityDelta': 15});
  });

  test('createProduct() skips the stock call when no storeId is available',
      () async {
    when(() => dio.post('/inventory/products',
            data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => _response({
              'success': true,
              'data': {'product': _productJson()}
            }));

    await repository.createProduct(_validDraft,
        initialStock: 15, storeId: null);

    verifyNever(() => dio.patch(any(),
        data: any(named: 'data'), options: any(named: 'options')));
  });

  test('updateProduct() patches the product', () async {
    when(() => dio.patch('/inventory/products/prod-1',
            data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => _response({
              'success': true,
              'data': {'product': _productJson()}
            }));

    final product = await repository.updateProduct('prod-1', _validDraft);

    expect(product.id, 'prod-1');
  });

  test('deleteProduct() calls DELETE on the product', () async {
    when(() =>
        dio.delete('/inventory/products/prod-1',
            options: any(named: 'options'))).thenAnswer((_) async => _response({
          'success': true,
          'data': {'product': _productJson()}
        }));

    await repository.deleteProduct('prod-1');

    verify(() => dio.delete('/inventory/products/prod-1',
        options: any(named: 'options'))).called(1);
  });

  test(
      'listCategories() returns distinct, sorted, non-empty categories from a bounded fetch',
      () async {
    when(() => dio.get('/inventory/products',
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'))).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {
          'products': [
            {..._productJson(id: 'p1'), 'category': 'Wax'},
            {..._productJson(id: 'p2'), 'category': 'Leashes'},
            {..._productJson(id: 'p3'), 'category': 'Wax'},
            {..._productJson(id: 'p4'), 'category': null},
          ],
          'nextCursor': null,
        },
      }),
    );

    final categories = await repository.listCategories();

    expect(categories, ['Leashes', 'Wax']);
  });

  group('Product Image', () {
    late File tempFile;

    setUp(() {
      tempFile = File(
          '${Directory.systemTemp.path}/product_image_test_${identityHashCode(imagePicker)}.jpg')
        ..writeAsBytesSync([0, 1, 2, 3]);
    });

    tearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    test('pickImageFromGallery() returns the path of an existing picked file',
        () async {
      when(() => imagePicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => XFile(tempFile.path));

      final path = await repository.pickImageFromGallery();

      expect(path, tempFile.path);
    });

    test(
        'captureImageFromCamera() returns the path of an existing captured file',
        () async {
      when(() => imagePicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => XFile(tempFile.path));

      final path = await repository.captureImageFromCamera();

      expect(path, tempFile.path);
    });

    test('returns null (not an error) when the user cancels the picker',
        () async {
      when(() => imagePicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => null);

      final path = await repository.pickImageFromGallery();

      expect(path, isNull);
    });

    test('throws ProductImageException when the picked file does not exist',
        () async {
      when(() => imagePicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => XFile('/no/such/file.jpg'));

      await expectLater(repository.pickImageFromGallery(),
          throwsA(isA<ProductImageException>()));
    });

    test('maps a permission-denied PlatformException to a clear message',
        () async {
      when(() => imagePicker.pickImage(source: ImageSource.camera)).thenThrow(
        PlatformException(code: 'camera_access_denied', message: 'denied'),
      );

      await expectLater(
        repository.captureImageFromCamera(),
        throwsA(isA<ProductImageException>().having(
          (e) => e.message,
          'message',
          contains('denied'),
        )),
      );
    });

    test(
        'maps an unexpected exception to a generic ProductImageException without crashing',
        () async {
      when(() => imagePicker.pickImage(source: ImageSource.gallery))
          .thenThrow(Exception('boom'));

      await expectLater(repository.pickImageFromGallery(),
          throwsA(isA<ProductImageException>()));
    });
  });
}
