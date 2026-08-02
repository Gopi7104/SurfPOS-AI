import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/inventory/widgets/product_quick_actions_sheet.dart';

import '../../authentication/fakes/fake_auth_repository.dart';
import '../fakes/fake_inventory_repository.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreSession: () async => testAuthUser())),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showProductQuickActionsSheet(context,
                  uid: 'uid-1', product: testProduct(name: 'Wax')),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows every action, with Print Label/Archive disabled',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Adjust Stock'), findsOneWidget);
    expect(find.text('Print Label'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNWidgets(2));
  });

  testWidgets('Duplicate opens Add Product prefilled, with SKU/barcode cleared',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Add Product'), findsOneWidget);
    expect(find.text('Wax'), findsOneWidget); // Name prefilled
    expect(find.text('WAX-01'), findsNothing); // source SKU not carried over
  });

  testWidgets('Delete shows a confirmation dialog first', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this product?'), findsOneWidget);
  });
}
