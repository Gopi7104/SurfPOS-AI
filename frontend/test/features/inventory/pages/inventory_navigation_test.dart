import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/exceptions/api_exception.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/dashboard/providers/dashboard_providers.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_page.dart';
import 'package:surfpos_ai/features/inventory/pages/inventory_home_page.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';

import '../../authentication/fakes/fake_auth_repository.dart';
import '../../dashboard/fakes/fake_dashboard_repository.dart';
import '../../merchant/presentation/screens/test_surface.dart';
import '../fakes/fake_inventory_repository.dart';

Widget _wrap({required FakeInventoryRepository inventory}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreSession: () async => testAuthUser())),
      dashboardRepositoryProvider.overrideWithValue(
        FakeDashboardRepository(
            loadDashboard: () async => testDashboardState()),
      ),
      inventoryRepositoryProvider.overrideWithValue(inventory),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const InventoryHomePage()),
  );
}

void main() {
  testWidgets('shows summary stats derived from the catalog sample',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        inventory: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async => InventoryPage(
            items: [
              testProduct(id: 'p1', stockQuantity: 0),
              testProduct(id: 'p2', stockQuantity: 2, lowStockThreshold: 5),
              testProduct(id: 'p3', stockQuantity: 50),
            ],
            nextCursor: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget); // Total Products
    expect(
        find.text('1'), findsNWidgets(2)); // Low Stock and Out of Stock, both 1
  });

  testWidgets(
      'Quick Actions navigate to Product List, Categories, and Add Product',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        inventory: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async =>
              const InventoryPage(items: [], nextCursor: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View All Products'));
    await tester.pumpAndSettle();
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('No Products'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('No Categories Yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets(
      'shows a "Complete Merchant Onboarding" prompt (not a stuck skeleton) '
      "when the caller hasn't onboarded yet", (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        inventory: FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async {
            throw const NotFoundApiException(
                'No merchant reference found for this account.');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete Merchant Onboarding'), findsOneWidget);
    expect(find.text('Quick Actions'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
