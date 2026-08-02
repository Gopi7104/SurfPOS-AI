import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_page.dart';
import 'package:surfpos_ai/features/inventory/repositories/product_lookup_repository.dart';
import 'package:surfpos_ai/features/inventory/repositories/product_lookup_repository_impl.dart';

import '../fakes/fake_inventory_repository.dart';
import '../fakes/fake_product_lookup_datasource.dart';

void main() {
  group('ProductLookupRepositoryImpl', () {
    test(
        'returns ProductLookupExisting and never calls any datasource when '
        'the barcode is already in this merchant\'s Inventory', () async {
      final existing = testProduct(id: 'p1', name: 'Blue Wave Surf Wax');
      final datasource = FakeProductLookupDatasource();
      final repository = ProductLookupRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async {
            expect(query.barcode, '7350123456783');
            return InventoryPage(items: [existing], nextCursor: null);
          },
        ),
        datasources: [datasource],
      );

      final outcome = await repository.lookup('7350123456783');

      expect(outcome, isA<ProductLookupExisting>());
      expect((outcome as ProductLookupExisting).product.id, 'p1');
      expect(datasource.calls, isEmpty);
    });

    test('returns ProductLookupFound from the first datasource with a record',
        () async {
      final result = testLookupResult(barcode: '3017620422003');
      final repository = ProductLookupRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async =>
              const InventoryPage(items: [], nextCursor: null),
        ),
        datasources: [
          FakeProductLookupDatasource(lookup: (barcode) async => result),
        ],
      );

      final outcome = await repository.lookup('3017620422003');

      expect(outcome, isA<ProductLookupFound>());
      expect((outcome as ProductLookupFound).result, same(result));
    });

    test(
        'falls through to the next datasource when an earlier one has no record',
        () async {
      final first = FakeProductLookupDatasource();
      final secondResult = testLookupResult(barcode: '111');
      final second =
          FakeProductLookupDatasource(lookup: (barcode) async => secondResult);
      final repository = ProductLookupRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async =>
              const InventoryPage(items: [], nextCursor: null),
        ),
        datasources: [first, second],
      );

      final outcome = await repository.lookup('111');

      expect(outcome, isA<ProductLookupFound>());
      expect((outcome as ProductLookupFound).result, same(secondResult));
      expect(first.calls, ['111']);
      expect(second.calls, ['111']);
    });

    test(
        'returns ProductLookupNotFound when neither Inventory nor any '
        'datasource has a record', () async {
      final repository = ProductLookupRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async =>
              const InventoryPage(items: [], nextCursor: null),
        ),
        datasources: [FakeProductLookupDatasource()],
      );

      final outcome = await repository.lookup('000');

      expect(outcome, isA<ProductLookupNotFound>());
    });

    test('propagates a datasource failure rather than swallowing it', () async {
      final repository = ProductLookupRepositoryImpl(
        inventoryRepository: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async =>
              const InventoryPage(items: [], nextCursor: null),
        ),
        datasources: [
          FakeProductLookupDatasource(
            lookup: (barcode) async => throw Exception('offline'),
          ),
        ],
      );

      expect(() => repository.lookup('000'), throwsA(isA<Exception>()));
    });
  });
}
