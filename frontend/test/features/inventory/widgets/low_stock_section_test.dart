import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/inventory/widgets/low_stock_section.dart';

import '../fakes/fake_inventory_repository.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('renders nothing when no product needs attention',
      (tester) async {
    await tester.pumpWidget(_wrap(LowStockSection(
      uid: 'uid-1',
      items: [testProduct(stockQuantity: 25)],
    )));

    expect(find.text('Needs Attention'), findsNothing);
  });

  testWidgets('shows a row per low/out-of-stock product, capped with "+N more"',
      (tester) async {
    await tester.pumpWidget(_wrap(LowStockSection(
      uid: 'uid-1',
      maxRows: 2,
      items: [
        testProduct(id: 'p1', name: 'Wax', stockQuantity: 0),
        testProduct(
            id: 'p2', name: 'Fin', stockQuantity: 2, lowStockThreshold: 5),
        testProduct(
            id: 'p3', name: 'Leash', stockQuantity: 1, lowStockThreshold: 5),
        testProduct(id: 'p4', name: 'Board', stockQuantity: 25),
      ],
    )));

    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('Wax'), findsOneWidget);
    expect(find.text('Fin'), findsOneWidget);
    expect(find.text('Leash'), findsNothing); // beyond maxRows
    expect(find.text('+1 more need attention'), findsOneWidget);
    expect(find.text('Board'), findsNothing); // in stock, never a candidate
  });

  testWidgets('Quick Restock opens a bottom sheet titled for the product',
      (tester) async {
    await tester.pumpWidget(_wrap(LowStockSection(
      uid: 'uid-1',
      items: [testProduct(name: 'Wax', stockQuantity: 0)],
    )));

    await tester.tap(find.text('Quick Restock'));
    await tester.pumpAndSettle();

    expect(find.text('Restock Wax'), findsOneWidget);
    expect(find.text('Quantity to add'), findsOneWidget);
  });
}
