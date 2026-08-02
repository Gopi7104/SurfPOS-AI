import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';
import 'package:surfpos_ai/features/inventory/repositories/product_lookup_repository.dart';

import '../fakes/fake_inventory_repository.dart';
import '../fakes/fake_product_lookup_datasource.dart';
import '../fakes/fake_product_lookup_repository.dart';

const _uidA = 'uid-a';
const _uidB = 'uid-b';

ProviderContainer _makeContainer(ProductLookupRepository repository) {
  return ProviderContainer(
    overrides: [productLookupRepositoryProvider.overrideWithValue(repository)],
  );
}

void main() {
  group('ProductLookupController', () {
    test('build() starts idle with no result', () {
      final container = _makeContainer(FakeProductLookupRepository());
      addTearDown(container.dispose);
      addTearDown(container
          .listen(productLookupControllerProvider(_uidA), (_, __) {})
          .close);

      final state = container.read(productLookupControllerProvider(_uidA));

      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.existingProduct, isNull);
      expect(state.notFoundBarcode, isNull);
      expect(state.errorMessage, isNull);
    });

    test('lookup() sets existingProduct on ProductLookupExisting', () async {
      final product = testProduct(id: 'p1');
      final container = _makeContainer(
        FakeProductLookupRepository(
          lookup: (barcode) async => ProductLookupExisting(product),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(container
          .listen(productLookupControllerProvider(_uidA), (_, __) {})
          .close);

      await container
          .read(productLookupControllerProvider(_uidA).notifier)
          .lookup('7350123456783');

      final state = container.read(productLookupControllerProvider(_uidA));
      expect(state.isLoading, isFalse);
      expect(state.existingProduct?.id, 'p1');
      expect(state.result, isNull);
      expect(state.notFoundBarcode, isNull);
    });

    test('lookup() sets result on ProductLookupFound', () async {
      final result = testLookupResult();
      final container = _makeContainer(
        FakeProductLookupRepository(
          lookup: (barcode) async => ProductLookupFound(result),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(container
          .listen(productLookupControllerProvider(_uidA), (_, __) {})
          .close);

      await container
          .read(productLookupControllerProvider(_uidA).notifier)
          .lookup('3017620422003');

      final state = container.read(productLookupControllerProvider(_uidA));
      expect(state.result, same(result));
      expect(state.existingProduct, isNull);
    });

    test('lookup() sets notFoundBarcode on ProductLookupNotFound', () async {
      final container = _makeContainer(
        FakeProductLookupRepository(
          lookup: (barcode) async => const ProductLookupNotFound(),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(container
          .listen(productLookupControllerProvider(_uidA), (_, __) {})
          .close);

      await container
          .read(productLookupControllerProvider(_uidA).notifier)
          .lookup('000');

      final state = container.read(productLookupControllerProvider(_uidA));
      expect(state.notFoundBarcode, '000');
      expect(state.result, isNull);
      expect(state.existingProduct, isNull);
    });

    test('lookup() surfaces a failure via errorMessage without crashing',
        () async {
      final container = _makeContainer(
        FakeProductLookupRepository(
          lookup: (barcode) async => throw Exception('offline'),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(container
          .listen(productLookupControllerProvider(_uidA), (_, __) {})
          .close);

      await container
          .read(productLookupControllerProvider(_uidA).notifier)
          .lookup('000');

      final state = container.read(productLookupControllerProvider(_uidA));
      expect(state.errorMessage, isNotNull);
      expect(state.result, isNull);
      expect(state.notFoundBarcode, isNull);
    });

    test('reset() clears every result slot back to idle', () async {
      final container = _makeContainer(
        FakeProductLookupRepository(
          lookup: (barcode) async => const ProductLookupNotFound(),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(container
          .listen(productLookupControllerProvider(_uidA), (_, __) {})
          .close);

      final notifier =
          container.read(productLookupControllerProvider(_uidA).notifier);
      await notifier.lookup('000');
      expect(
          container
              .read(productLookupControllerProvider(_uidA))
              .notFoundBarcode,
          isNotNull);

      notifier.reset();

      expect(
          container
              .read(productLookupControllerProvider(_uidA))
              .notFoundBarcode,
          isNull);
    });

    group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
      test('two different uids never share lookup state', () async {
        final containerA = _makeContainer(
          FakeProductLookupRepository(
            lookup: (barcode) async => const ProductLookupNotFound(),
          ),
        );
        addTearDown(containerA.dispose);
        final containerB = _makeContainer(FakeProductLookupRepository());
        addTearDown(containerB.dispose);
        addTearDown(containerA
            .listen(productLookupControllerProvider(_uidA), (_, __) {})
            .close);
        addTearDown(containerB
            .listen(productLookupControllerProvider(_uidB), (_, __) {})
            .close);

        await containerA
            .read(productLookupControllerProvider(_uidA).notifier)
            .lookup('000');

        expect(
            containerA
                .read(productLookupControllerProvider(_uidA))
                .notFoundBarcode,
            isNotNull);
        expect(
            containerB
                .read(productLookupControllerProvider(_uidB))
                .notFoundBarcode,
            isNull);
      });
    });
  });
}
