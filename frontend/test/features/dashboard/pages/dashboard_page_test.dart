import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/app/themes/app_theme.dart';
import 'package:surfpos_ai/core/storage/secure_storage_service.dart';
import 'package:surfpos_ai/features/authentication/providers/auth_providers.dart';
import 'package:surfpos_ai/features/dashboard/pages/dashboard_page.dart';
import 'package:surfpos_ai/features/dashboard/providers/dashboard_providers.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_business_snapshot.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_customer.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_product.dart';
import 'package:surfpos_ai/features/demo_data/models/demo_sale.dart';
import 'package:surfpos_ai/features/reports/models/recent_transaction.dart';

import '../../authentication/fakes/fake_auth_repository.dart';
import '../../merchant/presentation/screens/test_surface.dart';
import '../fakes/fake_dashboard_repository.dart';

/// In-memory [SecureStorageService] double, optionally pre-seeded — no
/// platform channel involved. Mirrors `main_shell_page_test.dart`'s own
/// fake.
class _FakeSecureStorageService implements SecureStorageService {
  _FakeSecureStorageService([Map<String, String>? seed]) : _values = {...?seed};

  final Map<String, String> _values;

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}

/// Replaces `pumpAndSettle()` for any test rendering `DashboardPage`:
/// `SurfAiFloatingButton`'s breathing/pulse animations repeat forever by
/// design, so `pumpAndSettle` would never see "no more frames scheduled"
/// and time out. A bounded, but repeated, set of pumps gives the page's own
/// one-shot transitions (FadeSlideIn, async provider loads chained across
/// more than one frame) enough chances to actually resolve, without ever
/// waiting on the perpetual animation.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
    await _settle(tester);
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
    await _settle(tester);

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
    await _settle(tester);

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await _settle(tester);

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
    await _settle(tester);

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
    await _settle(tester);

    await tester.tap(find.text('Inventory'));
    await tester.pump();

    expect(navigatedIndex, DashboardTabTargets.inventory);
  });

  // Regression test for the "can't scroll after touching a chart" bug: an
  // un-scaled fl_chart BarChart/LineChart arms a raw, omnidirectional
  // `PanGestureRecognizer` whenever touch is enabled (the old default here),
  // and — because it sits deeper in the tree than Dashboard's own ListView —
  // reliably wins the gesture arena over the page's own scroll for any drag
  // that starts on the chart. See `revenue_chart_section.dart`'s header
  // comment for the full root-cause explanation.
  testWidgets(
      'a vertical drag starting on the Revenue chart still scrolls the Dashboard',
      (tester) async {
    useTallTestSurface(tester);
    const uid = 'uid-1';
    // A small, fully-controlled snapshot (not `DemoDataGenerator`, which
    // uses unseeded `Random()` and can occasionally produce a low-stock
    // product — `LowStockSection` has its own pre-existing, unrelated
    // layout bug when it renders a real row, out of scope to touch here).
    // One healthy-stock product and one recent sale is enough for the
    // Revenue chart to have real data to plot.
    final now = DateTime.now();
    final snapshot = DemoBusinessSnapshot(
      merchantName: 'Blue Wave Surf Shop',
      storeName: 'Main Street Store',
      generatedAt: now,
      categories: const ['Surfboards'],
      products: const [
        DemoProduct(
          id: 'p1',
          name: 'Longboard',
          category: 'Surfboards',
          price: 100,
          costPrice: 60,
          stockQuantity: 50,
          lowStockThreshold: 5,
          unitsSold: 3,
          colorSeed: 0,
        ),
      ],
      customers: const [
        DemoCustomer(
            id: 'c1', name: 'Alex Rider', totalSpend: 300, totalOrders: 3),
      ],
      sales: [
        DemoSale(
          id: 's1',
          receiptNumber: 'R-1',
          time: now,
          amount: 100,
          costAmount: 60,
          paymentMethod: 'Card',
          productId: 'p1',
          productName: 'Longboard',
          customerName: 'Alex Rider',
          status: TransactionStatus.successful,
        ),
      ],
      receipts: const [],
    );
    final fakeStorage = _FakeSecureStorageService({
      'demo_data.snapshot.$uid': jsonEncode(snapshot.toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(
                loadDashboard: () async => testDashboardState()),
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
                restoreSession: () async => testAuthUser(uid: uid)),
          ),
          secureStorageServiceProvider.overrideWithValue(fakeStorage),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DashboardPage()),
        ),
      ),
    );
    await _settle(tester);

    // The demo dataset is present, so the real chart (not the "no activity
    // yet" empty state) is on screen.
    final chartFinder = find.byType(BarChart);
    expect(chartFinder, findsOneWidget);

    final scrollableFinder = find.byType(Scrollable).first;
    final scrollable = tester.state<ScrollableState>(scrollableFinder);
    final offsetBefore = scrollable.position.pixels;

    // Drag starting from the chart's own center — this is exactly the
    // gesture that used to be swallowed by fl_chart's internal pan
    // recognizer instead of reaching the ListView.
    await tester.dragFrom(tester.getCenter(chartFinder), const Offset(0, -300));
    await _settle(tester);
    // Scrolling this far mounts a further-down section for the first time,
    // arming its `FadeSlideIn` entrance animation's `Future.delayed` timer
    // (up to 220ms, see `dashboard_page.dart`). That timer isn't tied to any
    // ticking `AnimationController`, so the bounded pump above can return
    // before it fires (nothing else is scheduling frames in the interim) —
    // a pre-existing, unrelated quirk of `FadeSlideIn`, out of scope to fix
    // here. Flush it explicitly so it can't leak past this test as a
    // pending timer.
    await tester.pump(const Duration(milliseconds: 300));

    final offsetAfter = scrollable.position.pixels;
    expect(offsetAfter, greaterThan(offsetBefore));
  });
}
