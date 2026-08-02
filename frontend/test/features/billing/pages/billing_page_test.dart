import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/billing/pages/billing_page.dart';
import 'package:surfpos_ai/features/billing/providers/billing_providers.dart';
import 'package:surfpos_ai/features/billing/repositories/billing_repository.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';

import '../../authentication/fakes/fake_auth_repository.dart';
import '../../inventory/fakes/fake_inventory_repository.dart';
import '../../merchant/presentation/screens/test_surface.dart';
import '../fakes/fake_billing_repository.dart';

Widget _wrap(BillingRepository repository) {
  return ProviderScope(
    overrides: [
      billingRepositoryProvider.overrideWithValue(repository),
      // The product grid reads Inventory's own catalog list directly (see
      // `billing_page.dart`'s header comment) — faked here so the grid never
      // hits the real network in these tests.
      inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository()),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(restoreSession: () async => testAuthUser()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const BillingPage()),
  );
}

void main() {
  testWidgets('shows the empty cart state with no items', (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap(FakeBillingRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Cart is Empty'), findsOneWidget);
  });

  testWidgets(
      'typing a search query shows suggestions, and selecting one adds it to the cart',
      (tester) async {
    useTallTestSurface(tester);
    final product = testCartProduct(name: 'Blue Wave Surf Wax');
    await tester.pumpWidget(
      _wrap(FakeBillingRepository(
          searchProducts: (query, {limit = 10}) async => [product])),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'surf');
    await tester
        .pump(const Duration(milliseconds: 400)); // clear the search debounce
    await tester.pumpAndSettle();

    expect(find.text('Blue Wave Surf Wax'), findsOneWidget);

    await tester.tap(find.text('Blue Wave Surf Wax'));
    await tester.pumpAndSettle();

    expect(find.text('Cart is Empty'), findsNothing);
    expect(find.text('✓ Product Added: Blue Wave Surf Wax'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
  });

  testWidgets(
      'Clear Cart shows a confirmation dialog and empties the cart on confirm',
      (tester) async {
    useTallTestSurface(tester);
    final product = testCartProduct(name: 'Blue Wave Surf Wax');
    await tester.pumpWidget(
      _wrap(FakeBillingRepository(
          searchProducts: (query, {limit = 10}) async => [product])),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'surf');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Wave Surf Wax'));
    await tester.pumpAndSettle();

    // Let the "✓ Product Added" SnackBar finish its auto-dismiss timer — it
    // otherwise overlaps the cart bar at the bottom of the screen.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Open the full cart sheet, then Clear Cart from inside it.
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Clear cart?'), findsOneWidget);

    await tester.tap(find.text('Clear Cart').last);
    await tester.pumpAndSettle();

    expect(find.text('Cart is Empty'), findsOneWidget);
  });
}
