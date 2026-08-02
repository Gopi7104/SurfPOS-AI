import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/dashboard/pages/dashboard_page.dart';
import 'package:surfpos_ai/features/dashboard/providers/dashboard_providers.dart';

import '../../authentication/fakes/fake_auth_repository.dart';
import '../../merchant/presentation/screens/test_surface.dart';
import '../fakes/fake_dashboard_repository.dart';

Widget _wrap(Widget child, {required Override dashboardOverride}) {
  return ProviderScope(
    overrides: [
      dashboardOverride,
      // DashboardPage now keys its provider lookup on the authenticated uid — it must resolve to
      // a real (non-null) user, or the page shows AppFullScreenLoader instead of the dashboard.
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(restoreSession: () async => testAuthUser()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('shows a loading skeleton while the initial load is in flight',
      (tester) async {
    useTallTestSurface(tester);
    final completer = Completer<void>();
    await tester.pumpWidget(
      _wrap(
        const DashboardPage(),
        dashboardOverride: dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
            loadDashboard: () async {
              await completer.future;
              return testDashboardState();
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // No merchant content should be visible yet.
    expect(find.text('Merchant Information'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'shows the onboarding empty state when no merchant application exists',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        const DashboardPage(),
        dashboardOverride: dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
              loadDashboard: () async =>
                  testDashboardState(hasMerchant: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete Merchant Onboarding'), findsOneWidget);
    expect(find.text('Start Onboarding'), findsOneWidget);
  });

  testWidgets('shows an error state with retry when loading fails',
      (tester) async {
    useTallTestSurface(tester);
    var attempts = 0;
    await tester.pumpWidget(
      _wrap(
        const DashboardPage(),
        dashboardOverride: dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
            loadDashboard: () async {
              attempts++;
              if (attempts == 1) throw Exception('network down');
              return testDashboardState();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Blue Wave Surf Shop'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets(
      'renders merchant/store info, KPIs, and quick actions once loaded',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        const DashboardPage(),
        dashboardOverride: dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
              loadDashboard: () async => testDashboardState()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue Wave Surf Shop'), findsOneWidget);
    expect(find.textContaining('Main Street Store'), findsOneWidget);
    expect(find.text("Today's Revenue"), findsOneWidget);
    expect(find.text('New Sale'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('No business activity yet'), findsOneWidget);
  });

  testWidgets('tapping a Quick Action navigates to its tab', (tester) async {
    useTallTestSurface(tester);
    int? navigatedIndex;
    await tester.pumpWidget(
      _wrap(
        DashboardPage(onNavigateToTab: (index) => navigatedIndex = index),
        dashboardOverride: dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
              loadDashboard: () async => testDashboardState()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inventory'));
    await tester.pump();

    expect(navigatedIndex, DashboardTabTargets.inventory);
  });
}
