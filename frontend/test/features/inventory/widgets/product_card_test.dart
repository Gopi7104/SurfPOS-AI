import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/inventory/widgets/product_card.dart';

import '../fakes/fake_inventory_repository.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  testWidgets(
      'renders name, SKU, price, stock, category, and an Active status chip',
      (tester) async {
    await tester.pumpWidget(_wrap(ProductCard(product: testProduct())));

    expect(find.text('Blue Wave Surf Wax'), findsOneWidget);
    expect(find.text('SKU: WAX-01'), findsOneWidget);
    expect(find.text('\$19.99'), findsOneWidget);
    expect(find.text('25 pcs'), findsOneWidget);
    expect(find.text('Wax'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Low Stock'), findsNothing);
    expect(find.text('Out of Stock'), findsNothing);
  });

  testWidgets('shows a Low Stock badge when quantity is at/below the threshold',
      (tester) async {
    await tester.pumpWidget(
      _wrap(ProductCard(
          product: testProduct(stockQuantity: 5, lowStockThreshold: 5))),
    );

    expect(find.text('Low Stock'), findsOneWidget);
  });

  testWidgets(
      'shows an Out of Stock badge instead of Low Stock when quantity is 0',
      (tester) async {
    await tester.pumpWidget(
      _wrap(ProductCard(
          product: testProduct(stockQuantity: 0, lowStockThreshold: 5))),
    );

    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('Low Stock'), findsNothing);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
        _wrap(ProductCard(product: testProduct(), onTap: () => tapped = true)));

    await tester.tap(find.byType(ProductCard));

    expect(tapped, isTrue);
  });
}
