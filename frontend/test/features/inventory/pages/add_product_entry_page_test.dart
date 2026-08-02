import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/dashboard/providers/dashboard_providers.dart';
import 'package:surfpos_ai/features/inventory/models/inventory_page.dart';
import 'package:surfpos_ai/features/inventory/pages/add_product_entry_page.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';

import '../../authentication/fakes/fake_auth_repository.dart';
import '../../dashboard/fakes/fake_dashboard_repository.dart';
import '../../merchant/presentation/screens/test_surface.dart';
import '../fakes/fake_inventory_repository.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(restoreSession: () async => testAuthUser())),
      dashboardRepositoryProvider.overrideWithValue(
        FakeDashboardRepository(
            loadDashboard: () async => testDashboardState()),
      ),
      inventoryRepositoryProvider.overrideWithValue(
        FakeInventoryRepository(
          listProducts: (query, {cursor, limit = 20}) async =>
              const InventoryPage(items: [], nextCursor: null),
        ),
      ),
    ],
    child:
        MaterialApp(theme: AppTheme.light, home: const AddProductEntryPage()),
  );
}

void main() {
  testWidgets('shows both onboarding options', (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Scan Barcode'), findsOneWidget);
    expect(find.text('Enter Manually'), findsOneWidget);
  });

  testWidgets('"Enter Manually" opens the plain Add Product form',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enter Manually'));
    await tester.pumpAndSettle();

    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    // No barcode was prefilled — the manual path never seeds any field.
    expect(find.text('Barcode'), findsOneWidget);
  });
}
