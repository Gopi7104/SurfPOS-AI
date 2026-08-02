import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../models/diagnostics_snapshot.dart';
import '../providers/settings_providers.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/settings_navigation_tile.dart';
import '../widgets/settings_value_tile.dart';

/// Full diagnostics + developer utilities — reached from both Section 12
/// (Developer, dev-build-only on Settings Home) and Support's "Developer
/// Tools" link.
class DeveloperToolsPage extends ConsumerWidget {
  const DeveloperToolsPage({super.key});

  String _debugReport(DiagnosticsSnapshot d) {
    return '''SurfPOS AI Debug Report
Environment: ${d.environment}
API Base URL: ${d.apiBaseUrl ?? 'Not configured'}
Backend: ${d.backendStatus.label} (${d.backendResponseTime?.inMilliseconds ?? '—'} ms)
Surfboard: ${d.surfboardStatus.label}
Firebase: ${d.firebaseStatus.label}
Merchant ID: ${d.merchantId ?? '—'}
Store ID: ${d.storeId ?? '—'}
App Version: ${d.appVersion} (${d.buildNumber})
Device: ${d.deviceDescription}
''';
  }

  Future<void> _copyDeviceInfo(
      BuildContext context, DiagnosticsSnapshot d) async {
    await Clipboard.setData(ClipboardData(
        text:
            'Device: ${d.deviceDescription}\nApp Version: ${d.appVersion} (${d.buildNumber})'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device info copied to clipboard.')),
    );
  }

  Future<void> _exportDebugReport(DiagnosticsSnapshot d) async {
    await SharePlus.instance.share(ShareParams(
      text: _debugReport(d),
      subject: 'SurfPOS AI Debug Report',
    ));
  }

  Future<void> _confirmResetDemoData(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
            'This clears this device\'s saved Settings preferences back to '
            'defaults. It does not touch your Customers list, Inventory, or '
            'any online account data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(settingsControllerProvider(uid).notifier).resetToDefaults();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to defaults.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final diagnosticsAsync = ref.watch(diagnosticsControllerProvider(uid));

    return Scaffold(
      appBar: AppTopBar(
          title: 'Developer Tools', onBack: () => Navigator.of(context).pop()),
      body: switch (diagnosticsAsync) {
        AsyncLoading() when !diagnosticsAsync.hasValue =>
          const Center(child: AppLoadingIndicator()),
        AsyncError() when !diagnosticsAsync.hasValue => ErrorState(
            message: 'Could not load diagnostics.',
            onRetry: () =>
                ref.read(diagnosticsControllerProvider(uid).notifier).refresh(),
          ),
        _ => _buildBody(context, ref, uid, diagnosticsAsync.value!),
      },
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, String uid, DiagnosticsSnapshot d) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(diagnosticsControllerProvider(uid).notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ConnectionStatusCard(
            title: 'Services',
            entries: [
              ('Backend', d.backendStatus),
              ('Surfboard', d.surfboardStatus),
              ('Firebase', d.firebaseStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          SettingsValueTile(label: 'API URL', value: d.apiBaseUrl),
          SettingsValueTile(label: 'Current Environment', value: d.environment),
          SettingsValueTile(label: 'Current User', value: uid),
          SettingsValueTile(label: 'Merchant ID', value: d.merchantId),
          SettingsValueTile(label: 'Store ID', value: d.storeId),
          SettingsValueTile(label: 'App Version', value: d.appVersion),
          SettingsValueTile(label: 'Build Number', value: d.buildNumber),
          SettingsValueTile(label: 'Device', value: d.deviceDescription),
          const SizedBox(height: AppSpacing.sm + 2),
          SettingsNavigationTile(
            title: 'View Logs',
            onTap: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Coming Soon'))),
          ),
          SettingsNavigationTile(
            title: 'Copy Device Info',
            onTap: () => _copyDeviceInfo(context, d),
          ),
          SettingsNavigationTile(
            title: 'Export Debug Report',
            onTap: () => _exportDebugReport(d),
          ),
          SettingsNavigationTile(
            title: 'Reset Demo Data',
            onTap: () => _confirmResetDemoData(context, ref, uid),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
