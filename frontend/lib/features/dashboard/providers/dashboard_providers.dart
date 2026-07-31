import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../../merchant/presentation/providers/merchant_onboarding_providers.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_state.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/dashboard_repository_impl.dart';

/// DI wiring for the dashboard feature — reuses [apiClientProvider] (from
/// the authentication feature) and [merchantOnboardingApiServiceProvider]
/// (from the merchant feature) rather than redeclaring them, matching the
/// established cross-feature-provider-reuse convention (see
/// `merchant_onboarding_providers.dart`).

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    merchantApplicationApi: ref.watch(merchantOnboardingApiServiceProvider),
  );
});

/// Keyed by Firebase uid — never a global singleton (see
/// docs/22_DEVELOPMENT_ROADMAP.md, cross-user isolation fix). Merchant A's
/// and Merchant B's dashboards are two entirely separate provider instances
/// with independent state; `autoDispose` frees a previous user's cached
/// [DashboardState] the moment [DashboardPage] stops watching it (i.e. as
/// soon as the uid changes), so no stale data can outlive the session that
/// produced it — not even for a single frame.
final dashboardControllerProvider =
    AsyncNotifierProvider.autoDispose.family<DashboardController, DashboardState, String>(
  DashboardController.new,
);
