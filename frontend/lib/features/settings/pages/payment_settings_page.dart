import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/diagnostics_snapshot.dart';
import '../providers/settings_providers.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/settings_info_tile.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_value_tile.dart';

/// Payment section's dedicated page — Surfboard Configuration (Merchant/
/// Store status, read-only reuse of Dashboard's already-live data),
/// Terminal Status, Payment Sandbox, Connection Status, and Payment
/// Diagnostics. See `DiagnosticsController`'s header comment for exactly
/// what each status is derived from — this module makes no direct
/// Surfboard call of its own.
class PaymentSettingsPage extends ConsumerWidget {
  const PaymentSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final dashboard = ref.watch(dashboardControllerProvider(uid)).valueOrNull;
    final diagnosticsAsync = ref.watch(diagnosticsControllerProvider(uid));

    return Scaffold(
      appBar: AppTopBar(
          title: 'Payment', onBack: () => Navigator.of(context).pop()),
      body: switch (diagnosticsAsync) {
        AsyncLoading() when !diagnosticsAsync.hasValue =>
          const Center(child: AppLoadingIndicator()),
        AsyncError() when !diagnosticsAsync.hasValue => ErrorState(
            message: 'Could not load payment diagnostics.',
            onRetry: () =>
                ref.read(diagnosticsControllerProvider(uid).notifier).refresh(),
          ),
        _ => RefreshIndicator(
            onRefresh: () =>
                ref.read(diagnosticsControllerProvider(uid).notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                ConnectionStatusCard(
                  title: 'Surfboard Configuration',
                  entries: [
                    (
                      'Merchant Status',
                      dashboard?.hasMerchant == true
                          ? ServiceStatus.connected
                          : ServiceStatus.unknown
                    ),
                    (
                      'Store Status',
                      dashboard?.store?.status
                                  ?.toLowerCase()
                                  .contains('active') ==
                              true
                          ? ServiceStatus.connected
                          : ServiceStatus.unknown
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                const SettingsTile(
                  title: 'Terminal Status',
                  subtitle: 'Not available — this app never registers a '
                      'physical payment terminal (Checkout uses Surfboard\'s '
                      'hosted Payment Page).',
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                SettingsTile(
                  title: 'Payment Sandbox',
                  subtitle: AppEnvironment.current.isDevelopment
                      ? 'This is a development build.'
                      : 'This is a ${AppEnvironment.current.name} build.',
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                const SettingsTile(
                  title: 'Test Payment',
                  subtitle:
                      'Use the 🧪 Test Payment button on Checkout\'s Payment Summary screen.',
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                ConnectionStatusCard(
                  title: 'Connection Status',
                  entries: [
                    ('Backend', diagnosticsAsync.value!.backendStatus),
                    ('Surfboard', diagnosticsAsync.value!.surfboardStatus),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                SectionCard(
                  title: 'Payment Diagnostics',
                  child: _PaymentDiagnosticsDetail(
                      diagnostics: diagnosticsAsync.value!),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
      },
    );
  }
}

/// Payment Diagnostics detail block.
class _PaymentDiagnosticsDetail extends StatelessWidget {
  const _PaymentDiagnosticsDetail({required this.diagnostics});

  final DiagnosticsSnapshot diagnostics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsValueTile(label: 'Merchant ID', value: diagnostics.merchantId),
        SettingsValueTile(label: 'Store ID', value: diagnostics.storeId),
        SettingsInfoTile(
            label: 'Merchant Status', value: diagnostics.merchantStatus),
        SettingsInfoTile(label: 'Store Status', value: diagnostics.storeStatus),
        SettingsInfoTile(
          label: 'Backend Response Time',
          value: diagnostics.backendResponseTime == null
              ? null
              : '${diagnostics.backendResponseTime!.inMilliseconds} ms',
        ),
      ],
    );
  }
}
