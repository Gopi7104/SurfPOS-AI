import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_spacing.dart';
import '../../settings/models/diagnostics_snapshot.dart';
import '../../settings/widgets/developer_status_card.dart';
import '../../settings/widgets/settings_navigation_tile.dart';
import '../../settings/widgets/settings_value_tile.dart';
import '../pages/surf_ai_chat_page.dart';
import '../providers/ai_providers.dart';

/// SurfAI's slice of Settings' Developer section — AI provider, current
/// model, API status, and a real "Test Connection" round trip. Dropped
/// into `settings/pages/developer_tools_page.dart` as a single widget so
/// that file only needs one import + one insertion, not a rewrite (Settings
/// isn't on the "do not touch" list for Phase AI 1, but blast radius there
/// should still stay minimal — see docs/22_DEVELOPMENT_ROADMAP.md "Phase AI 1").
class AiDeveloperSection extends ConsumerWidget {
  const AiDeveloperSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(aiStatusControllerProvider);
    final testAsync = ref.watch(aiConnectionTestControllerProvider);

    final status = statusAsync.valueOrNull;
    final testResult = testAsync.valueOrNull;

    final serviceStatus = testAsync.isLoading
        ? ServiceStatus.unknown
        : (testResult != null
            ? (testResult.connected
                ? ServiceStatus.connected
                : ServiceStatus.disconnected)
            : (status == null
                ? ServiceStatus.unknown
                : (status.configured
                    ? ServiceStatus.unknown
                    : ServiceStatus.disconnected)));

    final latency =
        testResult?.latencyMs != null ? '${testResult!.latencyMs} ms' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeveloperStatusCard(
          title: 'SurfAI (OpenRouter)',
          status: serviceStatus,
          latency: latency,
          isRefreshing: testAsync.isLoading,
          onRefresh: () =>
              ref.read(aiConnectionTestControllerProvider.notifier).run(),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        SettingsValueTile(
            label: 'AI Provider', value: status?.provider ?? 'OpenRouter'),
        SettingsValueTile(label: 'Current Model', value: status?.activeModel),
        if (testResult?.error != null)
          SettingsValueTile(label: 'Last Test Error', value: testResult!.error),
        const SizedBox(height: AppSpacing.sm + 2),
        SettingsNavigationTile(
          title: 'Chat with SurfAI',
          subtitle: 'Ask anything about your business',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SurfAiChatPage()),
          ),
        ),
      ],
    );
  }
}
