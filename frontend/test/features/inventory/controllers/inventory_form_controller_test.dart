import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/inventory/models/product_draft.dart';
import 'package:surfpos_ai/features/inventory/models/product_image_exception.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';

import '../fakes/fake_inventory_repository.dart';

const _uidA = 'uid-merchant-a';
const _uidB = 'uid-merchant-b';

const _draft = ProductDraft(
  name: 'Wax',
  sku: 'WAX-01',
  unit: 'pcs',
  price: 19.99,
  costPrice: 9.99,
  taxPercentage: 0,
  discountPercentage: 0,
);

void main() {
  test('build() starts as null (idle) until create()/updateProduct() is called',
      () async {
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository())
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(inventoryFormControllerProvider(_uidA).future);

    expect(result, isNull);
  });

  test('create() transitions through loading to the created product', () async {
    final product = testProduct();
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
              createProduct: (draft, {initialStock, storeId}) async => product),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryFormControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryFormControllerProvider(_uidA).future);
    final future = container
        .read(inventoryFormControllerProvider(_uidA).notifier)
        .create(_draft);

    expect(container.read(inventoryFormControllerProvider(_uidA)).isLoading,
        isTrue);
    await future;

    expect(
        container.read(inventoryFormControllerProvider(_uidA)).value, product);
  });

  test('create() passes initialStock/storeId through to the repository',
      () async {
    int? capturedStock;
    String? capturedStoreId;
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            createProduct: (draft, {initialStock, storeId}) async {
              capturedStock = initialStock;
              capturedStoreId = storeId;
              return testProduct();
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryFormControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryFormControllerProvider(_uidA).future);
    await container
        .read(inventoryFormControllerProvider(_uidA).notifier)
        .create(
          _draft,
          initialStock: 25,
          storeId: 'store-1',
        );

    expect(capturedStock, 25);
    expect(capturedStoreId, 'store-1');
  });

  test('create() surfaces a failure (e.g. duplicate SKU) as AsyncError',
      () async {
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            createProduct: (draft, {initialStock, storeId}) =>
                throw Exception('duplicate sku'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryFormControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryFormControllerProvider(_uidA).future);
    await container
        .read(inventoryFormControllerProvider(_uidA).notifier)
        .create(_draft);

    expect(container.read(inventoryFormControllerProvider(_uidA)).hasError,
        isTrue);
  });

  test('create() is a no-op while a submission is already in flight', () async {
    var callCount = 0;
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            createProduct: (draft, {initialStock, storeId}) async {
              callCount++;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return testProduct();
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryFormControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryFormControllerProvider(_uidA).future);
    final notifier =
        container.read(inventoryFormControllerProvider(_uidA).notifier);
    final first = notifier.create(_draft);
    final second = notifier.create(_draft);
    await Future.wait([first, second]);

    expect(callCount, 1);
  });

  test(
      'updateProduct() adjusts stock by the delta when it changed, then re-fetches',
      () async {
    int? capturedDelta;
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            updateProduct: (productId, draft) async =>
                testProduct(stockQuantity: 10),
            adjustStock: (productId,
                {required storeId, required quantityDelta}) async {
              capturedDelta = quantityDelta;
            },
            getProduct: (productId) async => testProduct(stockQuantity: 20),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryFormControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryFormControllerProvider(_uidA).future);
    await container
        .read(inventoryFormControllerProvider(_uidA).notifier)
        .updateProduct(
          'prod-1',
          _draft,
          stockDelta: 10,
          storeId: 'store-1',
        );

    expect(capturedDelta, 10);
    expect(
        container
            .read(inventoryFormControllerProvider(_uidA))
            .value
            ?.stockQuantity,
        20);
  });

  test('updateProduct() skips the stock call when the delta is zero', () async {
    var adjustCallCount = 0;
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(
            updateProduct: (productId, draft) async => testProduct(),
            adjustStock: (productId,
                    {required storeId, required quantityDelta}) async =>
                adjustCallCount++,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(container
        .listen(inventoryFormControllerProvider(_uidA), (_, __) {})
        .close);

    await container.read(inventoryFormControllerProvider(_uidA).future);
    await container
        .read(inventoryFormControllerProvider(_uidA).notifier)
        .updateProduct(
          'prod-1',
          _draft,
          stockDelta: 0,
          storeId: 'store-1',
        );

    expect(adjustCallCount, 0);
  });

  group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
    test('two different uids never share form submission state', () async {
      final containerA = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            FakeInventoryRepository(
                createProduct: (draft, {initialStock, storeId}) async =>
                    testProduct()),
          ),
        ],
      );
      addTearDown(containerA.dispose);
      final containerB = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider
              .overrideWithValue(FakeInventoryRepository())
        ],
      );
      addTearDown(containerB.dispose);

      addTearDown(containerA
          .listen(inventoryFormControllerProvider(_uidA), (_, __) {})
          .close);
      await containerA.read(inventoryFormControllerProvider(_uidA).future);
      await containerA
          .read(inventoryFormControllerProvider(_uidA).notifier)
          .create(_draft);

      final resultB =
          await containerB.read(inventoryFormControllerProvider(_uidB).future);

      expect(containerA.read(inventoryFormControllerProvider(_uidA)).value,
          isNotNull);
      expect(resultB, isNull);
    });
  });

  group('Product Image (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
    test('pickFromGallery() delegates to the repository and returns its result',
        () async {
      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            FakeInventoryRepository(
                pickImageFromGallery: () async => '/tmp/a.jpg'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final path = await container
          .read(inventoryFormControllerProvider(_uidA).notifier)
          .pickFromGallery();

      expect(path, '/tmp/a.jpg');
    });

    test('takePhoto() delegates to the repository and returns its result',
        () async {
      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            FakeInventoryRepository(
                captureImageFromCamera: () async => '/tmp/b.jpg'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final path = await container
          .read(inventoryFormControllerProvider(_uidA).notifier)
          .takePhoto();

      expect(path, '/tmp/b.jpg');
    });

    test(
        'pickFromGallery() rethrows a ProductImageException from the repository',
        () async {
      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            FakeInventoryRepository(
              pickImageFromGallery: () async =>
                  throw const ProductImageException('Permission denied.'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(inventoryFormControllerProvider(_uidA).notifier)
            .pickFromGallery(),
        throwsA(isA<ProductImageException>()),
      );
    });

    test('removeImage() always resolves to null', () async {
      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider
              .overrideWithValue(FakeInventoryRepository())
        ],
      );
      addTearDown(container.dispose);

      final path = await container
          .read(inventoryFormControllerProvider(_uidA).notifier)
          .removeImage();

      expect(path, isNull);
    });
  });
}
