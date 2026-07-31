import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_state.dart';
import '../providers/dashboard_providers.dart';

/// Loads the Merchant Dashboard snapshot for exactly one Firebase uid (see
/// [dashboardControllerProvider] — this is a `.family` provider, the uid is
/// this notifier's `arg`, never read from elsewhere). Mirrors
/// `MerchantOnboardingController`'s shape otherwise: `build()` does the
/// initial load, `refresh()` guards against overlapping calls and re-runs
/// it for this same uid.
class DashboardController
    extends AutoDisposeFamilyAsyncNotifier<DashboardState, String> {
  @override
  Future<DashboardState> build(String uid) {
    return ref.read(dashboardRepositoryProvider).loadDashboard();
  }

  Future<void> refresh() async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(dashboardRepositoryProvider).loadDashboard());
  }
}
