import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/billing/providers/billing_providers.dart';
import 'package:surfpos_ai/features/billing/repositories/billing_repository.dart';

import '../fakes/fake_billing_repository.dart';

const _uidA = 'uid-a';
const _uidB = 'uid-b';

ProviderContainer _makeContainer(BillingRepository repository) {
  final container = ProviderContainer(
    overrides: [billingRepositoryProvider.overrideWithValue(repository)],
  );
  return container;
}

void main() {
  group('BillingController', () {
    test('build() starts with an empty cart', () {
      final container = _makeContainer(FakeBillingRepository());
      addTearDown(container.dispose);
      addTearDown(
          container.listen(billingControllerProvider(_uidA), (_, __) {}).close);

      final state = container.read(billingControllerProvider(_uidA));

      expect(state.isEmpty, isTrue);
      expect(state.items, isEmpty);
    });

    test('search() populates searchResults and toggles isSearching', () async {
      final product = testCartProduct(name: 'Blue Wave Surf Wax');
      final container = _makeContainer(
        FakeBillingRepository(
            searchProducts: (query, {limit = 10}) async => [product]),
      );
      addTearDown(container.dispose);
      addTearDown(
          container.listen(billingControllerProvider(_uidA), (_, __) {}).close);

      await container
          .read(billingControllerProvider(_uidA).notifier)
          .search('surf');

      final state = container.read(billingControllerProvider(_uidA));
      expect(state.isSearching, isFalse);
      expect(state.searchResults, [product]);
      expect(state.searchQuery, 'surf');
    });

    test(
        'search() with a blank query clears results without calling the repository',
        () async {
      var wasCalled = false;
      final container = _makeContainer(
        FakeBillingRepository(
          searchProducts: (query, {limit = 10}) async {
            wasCalled = true;
            return const [];
          },
        ),
      );
      addTearDown(container.dispose);
      addTearDown(
          container.listen(billingControllerProvider(_uidA), (_, __) {}).close);

      await container
          .read(billingControllerProvider(_uidA).notifier)
          .search('   ');

      expect(wasCalled, isFalse);
      expect(container.read(billingControllerProvider(_uidA)).searchResults,
          isEmpty);
    });

    test('search() surfaces a failure via searchError', () async {
      final container = _makeContainer(
        FakeBillingRepository(
          searchProducts: (query, {limit = 10}) async =>
              throw Exception('network down'),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(
          container.listen(billingControllerProvider(_uidA), (_, __) {}).close);

      await container
          .read(billingControllerProvider(_uidA).notifier)
          .search('surf');

      final state = container.read(billingControllerProvider(_uidA));
      expect(state.isSearching, isFalse);
      expect(state.searchError, isNotNull);
      expect(state.searchResults, isEmpty);
    });

    test('selectSearchResult() adds a new product and clears search state',
        () async {
      final product = testCartProduct(id: 'p1', name: 'Blue Wave Surf Wax');
      final container = _makeContainer(FakeBillingRepository());
      addTearDown(container.dispose);
      addTearDown(
          container.listen(billingControllerProvider(_uidA), (_, __) {}).close);

      container
          .read(billingControllerProvider(_uidA).notifier)
          .selectSearchResult(product);

      final state = container.read(billingControllerProvider(_uidA));
      expect(state.items, hasLength(1));
      expect(state.items.single.product.id, 'p1');
      expect(state.items.single.quantity, 1);
      expect(state.searchQuery, '');
      expect(state.searchResults, isEmpty);
      expect(state.lastAddedProductName, 'Blue Wave Surf Wax');
    });

    test(
        'selectSearchResult() increments quantity if the product is already in the cart',
        () async {
      final product = testCartProduct(id: 'p1');
      final container = _makeContainer(FakeBillingRepository());
      addTearDown(container.dispose);
      addTearDown(
          container.listen(billingControllerProvider(_uidA), (_, __) {}).close);

      final notifier =
          container.read(billingControllerProvider(_uidA).notifier);
      notifier.selectSearchResult(product);
      notifier.selectSearchResult(product);

      final state = container.read(billingControllerProvider(_uidA));
      expect(state.items, hasLength(1));
      expect(state.items.single.quantity, 2);
    });

    group('addProductByBarcode() — barcode scan logic', () {
      test('adds the matching product and sets lastAddedProductName when found',
          () async {
        final product = testCartProduct(id: 'p1', barcode: '7350123456783');
        final container = _makeContainer(
          FakeBillingRepository(
            findProductByBarcode: (barcode) async =>
                barcode == '7350123456783' ? product : null,
          ),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        await container
            .read(billingControllerProvider(_uidA).notifier)
            .addProductByBarcode('7350123456783');

        final state = container.read(billingControllerProvider(_uidA));
        expect(state.items, hasLength(1));
        expect(state.items.single.product.id, 'p1');
        expect(state.notFoundBarcode, isNull);
        expect(state.lastAddedProductName, product.name);
      });

      test(
          'increments quantity when the scanned product is already in the cart',
          () async {
        final product = testCartProduct(id: 'p1', barcode: '7350123456783');
        final container = _makeContainer(
          FakeBillingRepository(
              findProductByBarcode: (barcode) async => product),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(billingControllerProvider(_uidA).notifier);
        await notifier.addProductByBarcode('7350123456783');
        await notifier.addProductByBarcode('7350123456783');

        final state = container.read(billingControllerProvider(_uidA));
        expect(state.items, hasLength(1));
        expect(state.items.single.quantity, 2);
      });

      test('sets notFoundBarcode and adds nothing when no product matches',
          () async {
        final container = _makeContainer(
          FakeBillingRepository(findProductByBarcode: (barcode) async => null),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        await container
            .read(billingControllerProvider(_uidA).notifier)
            .addProductByBarcode('0000000000000');

        final state = container.read(billingControllerProvider(_uidA));
        expect(state.items, isEmpty);
        expect(state.notFoundBarcode, '0000000000000');
        expect(state.lastAddedProductName, isNull);
      });

      test('surfaces a lookup failure via searchError without adding a product',
          () async {
        final container = _makeContainer(
          FakeBillingRepository(
            findProductByBarcode: (barcode) async =>
                throw Exception('inventory unavailable'),
          ),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        await container
            .read(billingControllerProvider(_uidA).notifier)
            .addProductByBarcode('123');

        final state = container.read(billingControllerProvider(_uidA));
        expect(state.items, isEmpty);
        expect(state.searchError, isNotNull);
      });

      test('dismissNotFound() clears notFoundBarcode', () async {
        final container = _makeContainer(
          FakeBillingRepository(findProductByBarcode: (barcode) async => null),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(billingControllerProvider(_uidA).notifier);
        await notifier.addProductByBarcode('123');
        notifier.dismissNotFound();

        expect(container.read(billingControllerProvider(_uidA)).notFoundBarcode,
            isNull);
      });
    });

    group('cart mutations', () {
      test('increaseQuantity() and decreaseQuantity() adjust the matching line',
          () {
        final product = testCartProduct(id: 'p1');
        final container = _makeContainer(FakeBillingRepository());
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(billingControllerProvider(_uidA).notifier);
        notifier.selectSearchResult(product);
        notifier.increaseQuantity('p1');
        expect(
            container
                .read(billingControllerProvider(_uidA))
                .items
                .single
                .quantity,
            2);

        notifier.decreaseQuantity('p1');
        expect(
            container
                .read(billingControllerProvider(_uidA))
                .items
                .single
                .quantity,
            1);
      });

      test('decreaseQuantity() is a no-op below quantity 1', () {
        final product = testCartProduct(id: 'p1');
        final container = _makeContainer(FakeBillingRepository());
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(billingControllerProvider(_uidA).notifier);
        notifier.selectSearchResult(product);
        notifier.decreaseQuantity('p1');

        expect(
            container
                .read(billingControllerProvider(_uidA))
                .items
                .single
                .quantity,
            1);
      });

      test('removeItem() deletes the line entirely', () {
        final product = testCartProduct(id: 'p1');
        final container = _makeContainer(FakeBillingRepository());
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(billingControllerProvider(_uidA).notifier);
        notifier.selectSearchResult(product);
        notifier.removeItem('p1');

        expect(container.read(billingControllerProvider(_uidA)).items, isEmpty);
      });

      test('clearCart() empties the cart', () {
        final container = _makeContainer(FakeBillingRepository());
        addTearDown(container.dispose);
        addTearDown(container
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(billingControllerProvider(_uidA).notifier);
        notifier.selectSearchResult(testCartProduct(id: 'p1'));
        notifier.selectSearchResult(testCartProduct(id: 'p2'));
        notifier.clearCart();

        expect(container.read(billingControllerProvider(_uidA)).items, isEmpty);
      });
    });

    group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
      test('two different uids never share cart state', () {
        final containerA = _makeContainer(FakeBillingRepository());
        addTearDown(containerA.dispose);
        final containerB = _makeContainer(FakeBillingRepository());
        addTearDown(containerB.dispose);
        addTearDown(containerA
            .listen(billingControllerProvider(_uidA), (_, __) {})
            .close);
        addTearDown(containerB
            .listen(billingControllerProvider(_uidB), (_, __) {})
            .close);

        containerA
            .read(billingControllerProvider(_uidA).notifier)
            .selectSearchResult(testCartProduct(id: 'p1'));

        final stateA = containerA.read(billingControllerProvider(_uidA));
        final stateB = containerB.read(billingControllerProvider(_uidB));

        expect(stateA.items, hasLength(1));
        expect(stateB.items, isEmpty);
      });
    });
  });
}
