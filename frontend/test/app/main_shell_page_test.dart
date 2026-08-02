import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/main_shell_page.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/core/widgets/cards/app_card.dart';
import 'package:surfpos_ai/core/widgets/navigation/app_main_scaffold.dart';
import 'package:surfpos_ai/features/ai/widgets/surf_ai_floating_button.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/dashboard/providers/dashboard_providers.dart';
import 'package:surfpos_ai/features/inventory/providers/inventory_providers.dart';

import '../features/authentication/fakes/fake_auth_repository.dart';
import '../features/dashboard/fakes/fake_dashboard_repository.dart';
import '../features/inventory/fakes/fake_inventory_repository.dart';
import '../features/merchant/presentation/screens/test_surface.dart';

/// In-memory [SecureStorageService] double — no platform channel involved.
/// Every tab in [MainShellPage] is mounted at once (`IndexedStack` keeps
/// them all alive), so Settings/Customers reaching the real
/// `FlutterSecureStorage` platform channel here — which never resolves in
/// a widget test, unlike a bare `test()` — would leave their loading
/// skeletons animating forever and `pumpAndSettle` would never finish.
class _FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

/// Replaces `pumpAndSettle()`: every tab is mounted at once (`IndexedStack`),
/// so the Dashboard tab's `SurfAiFloatingButton` — whose breathing/pulse
/// animations repeat forever by design — is always in the tree here,
/// regardless of which tab is selected. `pumpAndSettle` would never see "no
/// more frames scheduled" and time out; a bounded, repeated set of pumps
/// still gives every tab's own one-shot transitions/async loads enough
/// chances to resolve.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _wrap() {
  return ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(
        FakeDashboardRepository(
            loadDashboard: () async => testDashboardState()),
      ),
      inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository()),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(restoreSession: () async => testAuthUser()),
      ),
      secureStorageServiceProvider
          .overrideWithValue(_FakeSecureStorageService()),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const MainShellPage()),
  );
}

void main() {
  testWidgets('shows all 5 tabs, defaulting to Dashboard', (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    for (final item in AppMainScaffold.items) {
      expect(find.text(item.label), findsWidgets);
    }
    expect(find.text('Blue Wave Surf Shop'), findsOneWidget);
  });

  testWidgets('switching tabs via the bottom nav shows the right screen',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    await tester.tap(find.text('Billing').last);
    await _settle(tester);
    expect(find.text('Cart is Empty'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await _settle(tester);
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Dashboard').last);
    await _settle(tester);
    expect(find.text('Blue Wave Surf Shop'), findsOneWidget);
  });

  testWidgets(
      'preserves scroll/tab state across switches (IndexedStack, not rebuilt)',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    // All 5 tab bodies exist simultaneously in the widget tree (IndexedStack
    // keeps every child mounted) rather than being created/destroyed per tab.
    expect(find.text('Blue Wave Surf Shop'), findsOneWidget);

    await tester.tap(find.text('Inventory').last);
    await _settle(tester);
    expect(find.text('No Products'), findsOneWidget);

    // The Dashboard's content is still in the tree underneath (IndexedStack),
    // not disposed — proven by returning to it without a reload flash.
    await tester.tap(find.text('Dashboard').last);
    await tester
        .pump(); // a single frame, no settle — an AsyncNotifier reload would still be loading
    expect(find.text('Blue Wave Surf Shop'), findsOneWidget);
  });

  testWidgets('Quick Actions on the Dashboard switch the shell tab',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    // 'New Sale' also labels the shell's own floating action button, so
    // disambiguate by tapping the Dashboard's Quick Action tile
    // specifically (an AppCard) rather than plain text.
    await tester.tap(find.widgetWithText(AppCard, 'New Sale'));
    await _settle(tester);

    expect(find.text('Cart is Empty'), findsOneWidget);
  });

  testWidgets(
      'the floating SurfAI button is hit-testable only on the Dashboard tab',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(_wrap());
    await _settle(tester);

    // IndexedStack keeps every tab mounted (see this file's own header
    // comment), so a plain `find.byType` would still find the button's
    // Widget instance underneath other tabs too — `.hitTestable()` is the
    // correct check here: it only matches what a real tap could actually
    // reach, i.e. what IndexedStack is currently painting on top.
    expect(find.byType(SurfAiFloatingButton).hitTestable(), findsOneWidget);

    await tester.tap(find.text('Billing').last);
    await _settle(tester);
    expect(find.byType(SurfAiFloatingButton).hitTestable(), findsNothing);

    await tester.tap(find.text('Inventory').last);
    await _settle(tester);
    expect(find.byType(SurfAiFloatingButton).hitTestable(), findsNothing);

    await tester.tap(find.text('Reports').last);
    await _settle(tester);
    expect(find.byType(SurfAiFloatingButton).hitTestable(), findsNothing);

    await tester.tap(find.text('Customers').last);
    await _settle(tester);
    expect(find.byType(SurfAiFloatingButton).hitTestable(), findsNothing);

    await tester.tap(find.text('Settings').last);
    await _settle(tester);
    expect(find.byType(SurfAiFloatingButton).hitTestable(), findsNothing);

    await tester.tap(find.text('Dashboard').last);
    await _settle(tester);
    expect(find.byType(SurfAiFloatingButton).hitTestable(), findsOneWidget);
  });
}
