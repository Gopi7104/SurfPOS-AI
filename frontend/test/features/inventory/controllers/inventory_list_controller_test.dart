import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_page.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_query.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';

import '../fakes/fake_inventory_repository.dart';

const _uidA = 'uid-merchant-a';
const _uidB = 'uid-merchant-b';

void main() {
  test('build() loads the first page with the default query', () async {
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            listProducts: (query, {cursor, limit = 20}) async {
              expect(query.hasActiveFilters, isFalse);
              expect(cursor, isNull);
              return InventoryPage(items: [testProduct()], nextCursor: null);
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(inventoryListControllerProvider(_uidA).future);

    expect(result.items, hasLength(1));
    expect(result.hasMore, isFalse);
  });

  test('applyQuery() replaces the loaded items with a fresh fetch', () async {
    var callCount = 0;
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            listProducts: (query, {cursor, limit = 20}) async {
              callCount++;
              return InventoryPage(
                items: [
                  testProduct(
                      id: 'prod-$callCount', name: query.search ?? 'default')
                ],
                nextCursor: null,
              );
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryListControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryListControllerProvider(_uidA).future);
    await container
        .read(inventoryListControllerProvider(_uidA).notifier)
        .applyQuery(
          const InventoryQuery(search: 'wax'),
        );

    final state = container.read(inventoryListControllerProvider(_uidA)).value!;
    expect(state.items.single.name, 'wax');
    expect(state.query.search, 'wax');
  });

  test('loadMore() appends the next page and updates the cursor', () async {
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            listProducts: (query, {cursor, limit = 20}) async {
              if (cursor == null) {
                return InventoryPage(
                    items: [testProduct(id: 'prod-1')], nextCursor: 'prod-1');
              }
              return InventoryPage(
                  items: [testProduct(id: 'prod-2')], nextCursor: null);
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryListControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryListControllerProvider(_uidA).future);
    await container
        .read(inventoryListControllerProvider(_uidA).notifier)
        .loadMore();

    final state = container.read(inventoryListControllerProvider(_uidA)).value!;
    expect(state.items.map((p) => p.id), ['prod-1', 'prod-2']);
    expect(state.hasMore, isFalse);
  });

  test('loadMore() is a no-op once there is no further page', () async {
    var listCallCount = 0;
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            listProducts: (query, {cursor, limit = 20}) async {
              listCallCount++;
              return InventoryPage(items: [testProduct()], nextCursor: null);
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryListControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryListControllerProvider(_uidA).future);
    listCallCount = 0;
    await container
        .read(inventoryListControllerProvider(_uidA).notifier)
        .loadMore();

    expect(listCallCount, 0);
  });

  test(
      'deleteProduct() removes the item from the loaded list without a refetch',
      () async {
    var listCallCount = 0;
    String? deletedId;
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            listProducts: (query, {cursor, limit = 20}) async {
              listCallCount++;
              return InventoryPage(
                  items: [testProduct(id: 'prod-1'), testProduct(id: 'prod-2')],
                  nextCursor: null);
            },
            deleteProduct: (productId) async => deletedId = productId,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryListControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryListControllerProvider(_uidA).future);
    listCallCount = 0;
    await container
        .read(inventoryListControllerProvider(_uidA).notifier)
        .deleteProduct('prod-1');

    expect(deletedId, 'prod-1');
    expect(listCallCount, 0);
    final state = container.read(inventoryListControllerProvider(_uidA)).value!;
    expect(state.items.map((p) => p.id), ['prod-2']);
  });

  group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
    test('two different uids never share loaded product lists', () async {
      final containerA = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            FakeInventoryRepository(
              listProducts: (query, {cursor, limit = 20}) async =>
                  InventoryPage(
                      items: [testProduct(name: 'Merchant A Product')],
                      nextCursor: null),
            ),
          ),
        ],
      );
      addTearDown(containerA.dispose);

      final containerB = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            FakeInventoryRepository(
              listProducts: (query, {cursor, limit = 20}) async =>
                  const InventoryPage(items: [], nextCursor: null),
            ),
          ),
        ],
      );
      addTearDown(containerB.dispose);

      final resultA =
          await containerA.read(inventoryListControllerProvider(_uidA).future);
      final resultB =
          await containerB.read(inventoryListControllerProvider(_uidB).future);

      expect(resultA.items, hasLength(1));
      expect(resultA.items.single.name, 'Merchant A Product');
      expect(resultB.items, isEmpty);
    });
  });
}
