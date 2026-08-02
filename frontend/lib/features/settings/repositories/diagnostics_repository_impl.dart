import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'diagnostics_repository.dart';

class DiagnosticsRepositoryImpl implements DiagnosticsRepository {
  DiagnosticsRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<BackendHealthCheck> checkBackendHealth() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final environment = AppEnvironment.current.name;

    String? apiBaseUrl;
    try {
      apiBaseUrl = ApiConfig.baseUrl;
    } catch (_) {
      apiBaseUrl = null;
    }

    final stopwatch = Stopwatch()..start();
    var isHealthy = false;
    try {
      await _apiClient.get('/health');
      isHealthy = true;
    } catch (_) {
      isHealthy = false;
    } finally {
      stopwatch.stop();
    }

    return BackendHealthCheck(
      isHealthy: isHealthy,
      responseTime: stopwatch.elapsed,
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      deviceDescription: _deviceDescription(),
    );
  }

  String _deviceDescription() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'Unknown device';
    }
  }
}
