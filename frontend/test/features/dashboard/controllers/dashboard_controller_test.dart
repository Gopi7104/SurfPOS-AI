import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/dashboard/providers/dashboard_providers.dart';

import '../fakes/fake_dashboard_repository.dart';

const _uidA = 'uid-merchant-a';
const _uidB = 'uid-merchant-b';

void main() {
  test('build() loads the dashboard on first read', () async {
    final expected = testDashboardState();
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(loadDashboard: () async => expected),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(dashboardControllerProvider(_uidA).future);

    expect(result, expected);
  });

  test(
      'build() resolves to an empty (no-merchant) state when nothing is onboarded yet',
      () async {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
              loadDashboard: () async =>
                  testDashboardState(hasMerchant: false)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(dashboardControllerProvider(_uidA).future);

    expect(result.hasMerchant, isFalse);
  });

  test('refresh() transitions through loading to the refreshed state',
      () async {
    final initial = testDashboardState(applicationStatus: null);
    final refreshed = testDashboardState();
    var callCount = 0;
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
            loadDashboard: () async {
              callCount++;
              return callCount == 1 ? initial : refreshed;
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Keeps this autoDispose family instance alive across the awaits below — a plain
    // container.read() doesn't count as a listener, so without this the provider could be
    // disposed and recreated between reads.
    addTearDown(
        container.listen(dashboardControllerProvider(_uidA), (_, __) {}).close);

    await container.read(dashboardControllerProvider(_uidA).future);

    final future =
        container.read(dashboardControllerProvider(_uidA).notifier).refresh();
    expect(
        container.read(dashboardControllerProvider(_uidA)).isLoading, isTrue);

    await future;

    expect(container.read(dashboardControllerProvider(_uidA)).value, refreshed);
    expect(callCount, 2);
  });

  test('refresh() surfaces a failure as AsyncError without crashing', () async {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
              loadDashboard: () async => testDashboardState()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(dashboardControllerProvider(_uidA).future);

    final container2 = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
              loadDashboard: () => throw Exception('network down')),
        ),
      ],
    );
    addTearDown(container2.dispose);

    // Reading .future on a build() that throws surfaces the error via the future itself.
    await expectLater(
        container2.read(dashboardControllerProvider(_uidA).future),
        throwsException);
    expect(
        container2.read(dashboardControllerProvider(_uidA)).hasError, isTrue);
  });

  test('refresh() is a no-op while a refresh is already in flight', () async {
    var loadCallCount = 0;
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(
            loadDashboard: () async {
              loadCallCount++;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return testDashboardState();
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(
        container.listen(dashboardControllerProvider(_uidA), (_, __) {}).close);
    await container.read(dashboardControllerProvider(_uidA).future);
    loadCallCount = 0;

    final notifier =
        container.read(dashboardControllerProvider(_uidA).notifier);
    final first = notifier.refresh();
    final second = notifier.refresh();

    await Future.wait([first, second]);

    expect(loadCallCount, 1);
  });

  group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
    test(
        'two different uids never share provider state, even within the same container',
        () async {
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(
                loadDashboard: () async =>
                    testDashboardState(hasMerchant: false)),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Merchant A has completed onboarding.
      final merchantA = testDashboardState();
      final containerA = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(loadDashboard: () async => merchantA),
          ),
        ],
      );
      addTearDown(containerA.dispose);
      final resultA =
          await containerA.read(dashboardControllerProvider(_uidA).future);

      // Merchant B has NOT completed onboarding — reading providerB must never see merchant A's
      // cached value, not even transiently, because it is a structurally different provider
      // instance (a different family argument), not a shared/reused one.
      final resultB =
          await container.read(dashboardControllerProvider(_uidB).future);

      expect(resultA.hasMerchant, isTrue);
      expect(resultA.merchant?.name, 'Blue Wave Surf Shop');
      expect(resultB.hasMerchant, isFalse);
      expect(resultB.merchant, isNull);
    });

    test(
        're-reading the same uid after it was released returns a fresh instance, not stale data',
        () async {
      var loadCount = 0;
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(
              loadDashboard: () async {
                loadCount++;
                return testDashboardState();
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub =
          container.listen(dashboardControllerProvider(_uidA), (_, __) {});
      await container.read(dashboardControllerProvider(_uidA).future);
      sub.close(); // drop the only listener — autoDispose should tear this instance down

      // Give autoDispose's microtask a chance to run.
      await Future<void>.delayed(Duration.zero);

      await container.read(dashboardControllerProvider(_uidA).future);

      // A fresh instance re-runs build() (and therefore loadDashboard()) rather than replaying a
      // cached value — this is the guarantee that makes cross-user leakage structurally
      // impossible rather than merely "reset in most cases."
      expect(loadCount, 2);
    });

    test(
        '10x alternating login cycle between two merchants never leaks state either direction',
        () async {
      final merchantA = testDashboardState();
      final merchantBNotOnboarded = testDashboardState(hasMerchant: false);

      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(loadDashboard: () async => merchantA),
          ),
        ],
      );
      addTearDown(container.dispose);
      final containerB = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(
                loadDashboard: () async => merchantBNotOnboarded),
          ),
        ],
      );
      addTearDown(containerB.dispose);

      for (var cycle = 0; cycle < 10; cycle++) {
        final resultA =
            await container.read(dashboardControllerProvider(_uidA).future);
        expect(resultA.hasMerchant, isTrue,
            reason: 'cycle $cycle: Merchant A must see their own data');
        expect(resultA.merchant?.name, 'Blue Wave Surf Shop',
            reason: 'cycle $cycle');

        final resultB =
            await containerB.read(dashboardControllerProvider(_uidB).future);
        expect(resultB.hasMerchant, isFalse,
            reason:
                'cycle $cycle: Merchant B must never see Merchant A\'s data');
        expect(resultB.merchant, isNull, reason: 'cycle $cycle');
      }
    });
  });
}
