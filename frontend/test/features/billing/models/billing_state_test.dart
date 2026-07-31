import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/billing/models/billing_state.dart';
import 'package:surfpos_ai/features/billing/models/cart_item_model.dart';

import '../fakes/fake_billing_repository.dart';

void main() {
  group('BillingState aggregate getters', () {
    test('isEmpty and itemCount reflect the cart contents', () {
      const empty = BillingState();
      expect(empty.isEmpty, isTrue);
      expect(empty.itemCount, 0);

      final withItems = BillingState(
        items: [
          CartItemModel(product: testCartProduct(id: 'p1'), quantity: 2),
          CartItemModel(product: testCartProduct(id: 'p2'), quantity: 3),
        ],
      );
      expect(withItems.isEmpty, isFalse);
      expect(withItems.itemCount, 5);
    });

    test(
        'subtotal, taxTotal, discountTotal and grandTotal sum across all lines',
        () {
      final state = BillingState(
        items: [
          CartItemModel(
            product: testCartProduct(
                id: 'p1', price: 100, taxPercentage: 10, discountPercentage: 0),
            quantity: 1,
          ),
          CartItemModel(
            product: testCartProduct(
                id: 'p2', price: 50, taxPercentage: 20, discountPercentage: 10),
            quantity: 2,
          ),
        ],
      );

      // Line 1: subtotal 100, discount 0, tax 10 -> total 110
      // Line 2: subtotal 100, discount 10, tax 18 (20% of 90) -> total 108
      expect(state.subtotal, 200);
      expect(state.discountTotal, 10);
      expect(state.taxTotal, 28);
      expect(state.grandTotal, 218);
    });

    test('copyWith clear-flags reset the corresponding field to null', () {
      const state = BillingState(
        searchError: 'boom',
        notFoundBarcode: '123',
        lastAddedProductName: 'Wax',
      );

      final cleared = state.copyWith(
        clearSearchError: true,
        clearNotFoundBarcode: true,
        clearLastAddedProductName: true,
      );

      expect(cleared.searchError, isNull);
      expect(cleared.notFoundBarcode, isNull);
      expect(cleared.lastAddedProductName, isNull);
    });
  });
}
