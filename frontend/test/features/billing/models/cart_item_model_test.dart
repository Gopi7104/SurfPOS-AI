import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/billing/models/cart_item_model.dart';

import '../fakes/fake_billing_repository.dart';

void main() {
  group('CartItemModel calculations', () {
    test('lineSubtotal is unit price times quantity', () {
      final item = CartItemModel(
        product: testCartProduct(
            price: 19.99, taxPercentage: 0, discountPercentage: 0),
        quantity: 3,
      );

      expect(item.lineSubtotal, closeTo(59.97, 0.001));
    });

    test('lineTax is applied on the (post-discount) subtotal', () {
      final item = CartItemModel(
        product: testCartProduct(
            price: 100, taxPercentage: 25, discountPercentage: 0),
        quantity: 2,
      );

      // subtotal = 200, discount = 0, tax = 25% of 200 = 50
      expect(item.lineSubtotal, 200);
      expect(item.lineDiscount, 0);
      expect(item.lineTax, 50);
      expect(item.lineTotal, 250);
    });

    test('lineDiscount reduces the base tax is computed on', () {
      final item = CartItemModel(
        product: testCartProduct(
            price: 100, taxPercentage: 10, discountPercentage: 20),
        quantity: 1,
      );

      // subtotal = 100, discount = 20% of 100 = 20, taxable = 80, tax = 10% of 80 = 8
      expect(item.lineSubtotal, 100);
      expect(item.lineDiscount, 20);
      expect(item.lineTax, 8);
      expect(item.lineTotal, 88);
    });

    test('zero tax and zero discount leaves the total equal to the subtotal',
        () {
      final item = CartItemModel(
        product:
            testCartProduct(price: 42, taxPercentage: 0, discountPercentage: 0),
        quantity: 4,
      );

      expect(item.lineTotal, item.lineSubtotal);
      expect(item.lineTotal, 168);
    });

    test('copyWith replaces only the quantity', () {
      final product = testCartProduct();
      final item = CartItemModel(product: product, quantity: 1);

      final updated = item.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.product, same(product));
    });
  });
}
