import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/inventory/widgets/inventory_hero_card.dart';

import '../fakes/fake_inventory_repository.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  testWidgets(
      'shows Total Products, Low/Out of Stock, Added Today, and Total Value',
      (tester) async {
    await tester.pumpWidget(_wrap(InventoryHeroCard(
      isApproximate: false,
      items: [
        testProduct(id: 'p1', stockQuantity: 0, price: 10),
        testProduct(
            id: 'p2', stockQuantity: 2, lowStockThreshold: 5, price: 10),
        testProduct(id: 'p3', stockQuantity: 50, price: 10),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget); // Products
    expect(find.text('1'), findsNWidgets(2)); // Low Stock + Out of Stock
    expect(find.text('0'), findsOneWidget); // Added Today (fixed fixture dates)
    // Total value: (0 + 2 + 50) * 10 = 520
    expect(find.text('\$520'), findsOneWidget);
  });

  testWidgets(
      'shows a "+" suffix on Total Products when the page is approximate',
      (tester) async {
    await tester.pumpWidget(_wrap(InventoryHeroCard(
      isApproximate: true,
      items: List.generate(5, (i) => testProduct(id: 'p$i')),
    )));
    await tester.pumpAndSettle();

    expect(find.text('5+'), findsOneWidget);
  });

  testWidgets('shows all-zero stats for an empty catalog', (tester) async {
    await tester.pumpWidget(const _EmptyHero());
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNWidgets(4));
  });
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: InventoryHeroCard(items: [], isApproximate: false),
      ),
    );
  }
}
