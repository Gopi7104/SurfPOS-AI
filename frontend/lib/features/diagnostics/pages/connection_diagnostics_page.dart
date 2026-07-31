import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_config.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/app_card.dart';

enum _TestOutcome { idle, testing, success, failure }

/// TEMPORARY diagnostic screen for the "app can't reach the backend after
/// switching Wi-Fi networks" investigation — see
/// docs/23_ENVIRONMENT_CONFIGURATION.md and the connectivity-audit report.
/// Safe to delete once the root cause is confirmed and resolved on the
/// developer's machine/network; not linked from anywhere except a single
/// entry point in Settings (also marked TEMPORARY).
///
/// Deliberately bypasses [ApiClient]'s envelope-unwrapping/error-mapping and
/// talks to the backend with a bare [Dio] instance instead — still reading
/// the exact same [ApiConfig.baseUrl] every real repository uses, but this
/// way the *raw* [DioException]/[SocketException] reaches the screen
/// unmodified, which is what a connectivity diagnostic needs to show.
class ConnectionDiagnosticsPage extends StatefulWidget {
  const ConnectionDiagnosticsPage({super.key});

  @override
  State<ConnectionDiagnosticsPage> createState() =>
      _ConnectionDiagnosticsPageState();
}

class _ConnectionDiagnosticsPageState extends State<ConnectionDiagnosticsPage> {
  _TestOutcome _outcome = _TestOutcome.idle;
  int? _statusCode;
  Duration? _elapsed;
  String? _errorMessage;
  String? _socketExceptionDetail;
  String? _configError;

  @override
  void initState() {
    super.initState();
    // Print the resolved value at the moment this screen opens, in addition
    // to main.dart's startup print — useful if the app was already running
    // (hot reload) when API_BASE_URL's underlying .env was edited.
    debugPrint(
        '[ConnectionDiagnostics] AppEnvironment.current = ${AppEnvironment.current.name}');
    try {
      debugPrint(
          '[ConnectionDiagnostics] ApiConfig.baseUrl = ${ApiConfig.baseUrl}');
    } catch (error) {
      debugPrint('[ConnectionDiagnostics] ApiConfig.baseUrl threw: $error');
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _outcome = _TestOutcome.testing;
      _statusCode = null;
      _elapsed = null;
      _errorMessage = null;
      _socketExceptionDetail = null;
      _configError = null;
    });

    final String baseUrl;
    try {
      baseUrl = ApiConfig.baseUrl;
    } catch (error) {
      setState(() {
        _outcome = _TestOutcome.failure;
        _configError = error.toString();
      });
      return;
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ));
    final stopwatch = Stopwatch()..start();

    try {
      final response = await dio.get<dynamic>('/health');
      stopwatch.stop();
      setState(() {
        _outcome = _TestOutcome.success;
        _statusCode = response.statusCode;
        _elapsed = stopwatch.elapsed;
      });
    } on DioException catch (error) {
      stopwatch.stop();
      final underlying = error.error;
      setState(() {
        _outcome = _TestOutcome.failure;
        _statusCode = error.response?.statusCode;
        _elapsed = stopwatch.elapsed;
        _errorMessage =
            '${error.type.name}: ${error.message ?? error.toString()}';
        _socketExceptionDetail = underlying is SocketException
            ? _describeSocketException(underlying)
            : null;
      });
    } catch (error) {
      stopwatch.stop();
      setState(() {
        _outcome = _TestOutcome.failure;
        _elapsed = stopwatch.elapsed;
        _errorMessage = error.toString();
      });
    } finally {
      dio.close();
    }
  }

  String _describeSocketException(SocketException error) {
    final parts = <String>[error.message];
    if (error.osError != null) parts.add('OS error: ${error.osError}');
    if (error.address != null) parts.add('address: ${error.address!.address}');
    if (error.port != null) parts.add('port: ${error.port}');
    return parts.join(' — ');
  }

  @override
  Widget build(BuildContext context) {
    String? resolvedBaseUrl;
    String? baseUrlError;
    try {
      resolvedBaseUrl = ApiConfig.baseUrl;
    } catch (error) {
      baseUrlError = error.toString();
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Connection Diagnostics'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DiagnosticRow(
                        label: 'API Base URL',
                        value: resolvedBaseUrl ?? 'Not configured'),
                    _DiagnosticRow(
                        label: 'Environment',
                        value: AppEnvironment.current.name),
                    if (baseUrlError != null)
                      _DiagnosticRow(
                          label: 'Config Error',
                          value: baseUrlError,
                          isError: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DiagnosticRow(
                        label: 'Connection Test Result', value: _resultLabel),
                    _DiagnosticRow(
                        label: 'HTTP Status',
                        value: _statusCode?.toString() ?? '—'),
                    _DiagnosticRow(
                      label: 'Response Time',
                      value: _elapsed == null
                          ? '—'
                          : '${_elapsed!.inMilliseconds} ms',
                    ),
                    _DiagnosticRow(
                      label: 'Error Message',
                      value: _errorMessage ?? _configError ?? '—',
                      isError: _outcome == _TestOutcome.failure,
                    ),
                    _DiagnosticRow(
                      label: 'Socket Exception',
                      value: _socketExceptionDetail ?? 'None',
                      isError: _socketExceptionDetail != null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Test Backend Connection',
                isLoading: _outcome == _TestOutcome.testing,
                onPressed:
                    _outcome == _TestOutcome.testing ? null : _testConnection,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _resultLabel => switch (_outcome) {
        _TestOutcome.idle => 'Not tested yet',
        _TestOutcome.testing => 'Testing…',
        _TestOutcome.success => '✅ Connected',
        _TestOutcome.failure => '❌ Failed',
      };
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow(
      {required this.label, required this.value, this.isError = false});

  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: AppTypography.bodyMD.copyWith(
              fontWeight: FontWeight.w600,
              color: isError ? AppColors.error : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
