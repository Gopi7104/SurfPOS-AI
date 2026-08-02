import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/diagnostics_snapshot.dart';
import '../providers/settings_providers.dart';

/// Diagnostics for exactly one Firebase uid (see
/// [diagnosticsControllerProvider] — a `.family` provider). Combines a
/// real `/health` call ([DiagnosticsRepository.checkBackendHealth]) with
/// two read-only signals this module derives rather than fetching itself:
///
/// - **Surfboard health** — Dashboard already does a live `GET /merchant`
///   Surfboard round trip on its own `build()`; if that succeeded and
///   [DashboardState.hasMerchant] is true, Surfboard is reachable by
///   construction. Reading `dashboardControllerProvider(uid)`'s already-
///   loaded value (never calling anything on it that mutates Dashboard's
///   own state) avoids a second, redundant Surfboard call this module has
///   no repository of its own to make anyway (Surfboard integration is
///   out of scope to touch).
/// - **Firebase status** — `authControllerProvider` holding a signed-in
///   user *is* Firebase working; there's nothing else to check.
class DiagnosticsController
    extends AutoDisposeFamilyAsyncNotifier<DiagnosticsSnapshot, String> {
  @override
  Future<DiagnosticsSnapshot> build(String uid) => _load(uid);

  Future<DiagnosticsSnapshot> _load(String uid) async {
    final health =
        await ref.read(diagnosticsRepositoryProvider).checkBackendHealth();

    final dashboard = ref.read(dashboardControllerProvider(uid)).valueOrNull;
    final authUser = ref.read(authControllerProvider).valueOrNull;

    return DiagnosticsSnapshot(
      backendStatus: health.isHealthy
          ? ServiceStatus.connected
          : ServiceStatus.disconnected,
      backendResponseTime: health.responseTime,
      surfboardStatus: dashboard == null
          ? ServiceStatus.unknown
          : (dashboard.hasMerchant
              ? ServiceStatus.connected
              : ServiceStatus.disconnected),
      firebaseStatus:
          authUser != null ? ServiceStatus.connected : ServiceStatus.unknown,
      environment: health.environment,
      apiBaseUrl: health.apiBaseUrl,
      merchantId: dashboard?.merchant?.id,
      storeId: dashboard?.store?.id,
      merchantStatus: dashboard?.applicationStatus?.label,
      storeStatus: dashboard?.store?.status,
      appVersion: health.appVersion,
      buildNumber: health.buildNumber,
      deviceDescription: health.deviceDescription,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(arg));
  }
}
