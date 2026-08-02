/// What [DiagnosticsRepositoryImpl] alone can determine — a real backend
/// `/health` call plus this build's own config/version/device info. It
/// deliberately does **not** know about Surfboard/Firebase connectivity:
/// those are read-only signals [DiagnosticsController] derives from
/// Dashboard's/Authentication's already-live provider state instead of a
/// second network call (see [DiagnosticsController]'s header comment).
class BackendHealthCheck {
  const BackendHealthCheck({
    required this.isHealthy,
    this.responseTime,
    required this.environment,
    this.apiBaseUrl,
    required this.appVersion,
    required this.buildNumber,
    required this.deviceDescription,
  });

  final bool isHealthy;
  final Duration? responseTime;
  final String environment;
  final String? apiBaseUrl;
  final String appVersion;
  final String buildNumber;
  final String deviceDescription;
}

/// Seam for everything the Developer/Payment sections' diagnostics need
/// that this module can determine on its own.
abstract class DiagnosticsRepository {
  Future<BackendHealthCheck> checkBackendHealth();
}
