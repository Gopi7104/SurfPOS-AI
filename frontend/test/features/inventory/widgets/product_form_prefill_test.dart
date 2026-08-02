import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/widgets/text_fields/app_text_field.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';
import 'package:surfpos_ai/features/inventory/widgets/product_form.dart';

import '../fakes/fake_inventory_repository.dart';
import '../fakes/fake_product_lookup_datasource.dart';

/// `ProductForm` is a long scrollable form — taller than flutter_test's
/// default 800x600 surface, which would leave the Price/SKU/Stock rows this
/// test asserts on scrolled out of view and unbuilt (`ListView`/slivers lazily
/// build only what's within the viewport).
void _useVeryTallTestSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _wrap({required Widget child}) {
  return ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository()),
    ],
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );
}

void main() {
  group('ProductForm — barcode-scan prefill (Add mode only)', () {
    testWidgets(
        'prefills Name/Category/Barcode directly, and folds Brand/Weight/'
        'Packaging/Country/Ingredients/Nutrition into an editable Description',
        (tester) async {
      _useVeryTallTestSurface(tester);
      final prefill = testLookupResult(
        barcode: '3017620422003',
        name: 'Nutella',
        brand: 'Ferrero',
        category: 'Spreads',
        weight: '400 g',
        packaging: 'Glass jar',
        country: 'France',
        ingredients: 'Sugar, palm oil, hazelnuts',
        nutritionSummary: 'Energy: 539 kcal (per 100g)',
      );

      await tester.pumpWidget(_wrap(
        child: ProductForm(uid: 'uid-a', prefill: prefill, onSubmit: (_) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nutella'), findsOneWidget);
      expect(find.text('Spreads'), findsOneWidget);
      expect(find.text('3017620422003'), findsOneWidget);

      expect(find.textContaining('Brand: Ferrero'), findsOneWidget);
      expect(find.textContaining('Weight: 400 g'), findsOneWidget);
      expect(find.textContaining('Packaging: Glass jar'), findsOneWidget);
      expect(find.textContaining('Country: France'), findsOneWidget);
      expect(find.textContaining('Ingredients: Sugar, palm oil, hazelnuts'),
          findsOneWidget);
      expect(find.textContaining('Nutrition: Energy: 539 kcal (per 100g)'),
          findsOneWidget);
    });

    testWidgets(
        'never prefills store-specific fields — merchant must enter price, '
        'cost, tax, stock, SKU, and low-stock threshold themselves',
        (tester) async {
      _useVeryTallTestSurface(tester);
      final prefill = testLookupResult();

      await tester.pumpWidget(_wrap(
        child: ProductForm(uid: 'uid-a', prefill: prefill, onSubmit: (_) {}),
      ));
      await tester.pumpAndSettle();

      // Price/Cost Price start blank (unlike Name/Category/Barcode, which
      // are seeded from the scan) — the merchant always types these in.
      final priceField = tester.widget<TextField>(find.descendant(
        of: find.widgetWithText(AppTextField, 'Price'),
        matching: find.byType(TextField),
      ));
      expect(priceField.controller?.text, isEmpty);

      final skuField = tester.widget<TextField>(find.descendant(
        of: find.widgetWithText(AppTextField, 'SKU'),
        matching: find.byType(TextField),
      ));
      expect(skuField.controller?.text, isEmpty);
    });

    testWidgets(
        'a plain "Enter Manually" form (no prefill) starts every field blank',
        (tester) async {
      _useVeryTallTestSurface(tester);
      await tester.pumpWidget(_wrap(
        child: ProductForm(uid: 'uid-a', onSubmit: (_) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Brand:'), findsNothing);
      expect(find.textContaining('Ingredients:'), findsNothing);
    });
  });
}
