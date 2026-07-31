import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/billing/repositories/billing_repository_impl.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_page.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_query.dart';

import '../../inventory/fakes/fake_inventory_repository.dart';
import '../fakes/fake_billing_repository.dart';

void main() {
  group('BillingRepositoryImpl', () {
    test(
        'searchProducts delegates to InventoryRepository.listProducts with a fuzzy search query',
        () async {
      InventoryQuery? capturedQuery;
      int? capturedLimit;
      final product = testCartProduct(id: 'p1', name: 'Blue Wave Surf Wax');

      final inventory = FakeInventoryRepository(
        listProducts: (query, {cursor, limit = 20}) async {
          capturedQuery = query;
          capturedLimit = limit;
          return InventoryPage(items: [product], nextCursor: null);
        },
      );
      final repository = BillingRepositoryImpl(inventoryRepository: inventory);

      final results = await repository.searchProducts('surf', limit: 5);

      expect(results, [product]);
      expect(capturedQuery?.search, 'surf');
      expect(capturedQuery?.barcode, isNull);
      expect(capturedLimit, 5);
    });

    test(
        'searchProducts returns an empty list for a blank query without calling Inventory',
        () async {
      var wasCalled = false;
      final inventory = FakeInventoryRepository(
        listProducts: (query, {cursor, limit = 20}) async {
          wasCalled = true;
          return const InventoryPage(items: [], nextCursor: null);
        },
      );
      final repository = BillingRepositoryImpl(inventoryRepository: inventory);

      final results = await repository.searchProducts('   ');

      expect(results, isEmpty);
      expect(wasCalled, isFalse);
    });

    test('findProductByBarcode delegates with an exact-match barcode query',
        () async {
      InventoryQuery? capturedQuery;
      final product = testCartProduct(id: 'p1', barcode: '7350123456783');

      final inventory = FakeInventoryRepository(
        listProducts: (query, {cursor, limit = 20}) async {
          capturedQuery = query;
          return InventoryPage(items: [product], nextCursor: null);
        },
      );
      final repository = BillingRepositoryImpl(inventoryRepository: inventory);

      final result = await repository.findProductByBarcode('7350123456783');

      expect(result, product);
      expect(capturedQuery?.barcode, '7350123456783');
      expect(capturedQuery?.search, isNull);
    });

    test('findProductByBarcode returns null when no product matches', () async {
      final inventory = FakeInventoryRepository(
        listProducts: (query, {cursor, limit = 20}) async =>
            const InventoryPage(items: [], nextCursor: null),
      );
      final repository = BillingRepositoryImpl(inventoryRepository: inventory);

      final result = await repository.findProductByBarcode('0000000000000');

      expect(result, isNull);
    });
  });
}
