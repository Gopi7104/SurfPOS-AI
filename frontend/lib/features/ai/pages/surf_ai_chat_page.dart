import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell_navigation_providers.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/widgets/app_bars/glass_header.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/pages/dashboard_page.dart' show DashboardTabTargets;
import '../../dashboard/providers/dashboard_providers.dart';
import '../../demo_data/providers/demo_data_providers.dart';
import '../../inventory/pages/add_product_entry_page.dart';
import '../controllers/ai_chat_state.dart';
import '../models/ai_chat_reply.dart';
import '../models/chat_message.dart';
import '../providers/ai_providers.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_suggestions.dart';
import '../widgets/chat_typing_indicator.dart';
import '../widgets/surf_ai_floating_button.dart';

/// SurfAI's chat screen — reached from Settings' Developer section, or from
/// the floating SurfAI button on the Dashboard (see
/// `SurfAiFloatingButton`) via a [Hero] flight from the same badge shape.
class SurfAiChatPage extends ConsumerWidget {
  const SurfAiChatPage({super.key});

  /// Performs the actual routing/state-mutation for a `source: 'navigation'`
  /// reply — a Riverpod Notifier has no `BuildContext`, so this can't live
  /// in `AiChatController` itself; it just decides *which* action to take
  /// (see `AiChatState.pendingNavigationAction`'s header comment).
  void _handleNavigationAction(
    BuildContext context,
    WidgetRef ref,
    String uid,
    NavigationAction action,
  ) {
    void switchTab(int index) {
      ref.read(shellTabIndexProvider.notifier).state = index;
      Navigator.of(context).pop();
    }

    switch (action.type) {
      case 'openDashboard':
        switchTab(0);
      case 'openBilling':
      case 'startNewSale':
        switchTab(DashboardTabTargets.billing);
      case 'openInventory':
        switchTab(DashboardTabTargets.inventory);
      case 'openReports':
        switchTab(DashboardTabTargets.analytics);
      case 'openCustomers':
        switchTab(DashboardTabTargets.customers);
      case 'openSettings':
        switchTab(DashboardTabTargets.settings);
      case 'searchInventory':
        final query = action.params['query'] as String? ?? '';
        ref.read(pendingInventorySearchProvider.notifier).state = query;
        switchTab(DashboardTabTargets.inventory);
      case 'openAddProduct':
        ref.read(shellTabIndexProvider.notifier).state =
            DashboardTabTargets.inventory;
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddProductEntryPage()),
        );
      case 'generateDemoData':
        if (AppEnvironment.current.isDevelopment) {
          final dashboard =
              ref.read(dashboardControllerProvider(uid)).valueOrNull;
          ref.read(demoDataControllerProvider(uid).notifier).generate(
                merchantName: dashboard?.merchant?.name,
                storeName: dashboard?.store?.name,
              );
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final state = ref.watch(aiChatControllerProvider(uid));
    final controller = ref.read(aiChatControllerProvider(uid).notifier);

    ref.listen(aiChatControllerProvider(uid), (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        controller.dismissError();
      }
      final action = next.pendingNavigationAction;
      if (action != null) {
        _handleNavigationAction(context, ref, uid, action);
        controller.clearPendingNavigation();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GlassHeader(
            title: 'SurfAI',
            subtitle: 'Ask anything about your business',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Hero(tag: surfAiHeroTag, child: SurfAiBadge(size: 32)),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white, size: 18),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ChatBody(
              uid: uid,
              state: state,
              onSuggestion: controller.sendMessage,
              onRegenerate: controller.regenerateLast,
            ),
          ),
          ChatInputBar(
              onSend: controller.sendMessage, isSending: state.isSending),
        ],
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.uid,
    required this.state,
    required this.onSuggestion,
    required this.onRegenerate,
  });

  final String uid;
  final AiChatState state;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (state.messages.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ChatSuggestions(uid: uid, onSelect: onSuggestion),
      );
    }

    final lastAssistantIndex = state.messages.lastIndexWhere(
      (m) => m.role == ChatRole.assistant,
    );

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.messages.length + (state.isSending ? 1 : 0),
      itemBuilder: (context, reverseIndex) {
        if (state.isSending && reverseIndex == 0) {
          return ChatTypingBubble(
            label: state.isLikelyToolQuery
                ? 'SurfAI is checking your business...'
                : 'SurfAI is thinking...',
          );
        }
        final index = state.messages.length -
            1 -
            (state.isSending ? reverseIndex - 1 : reverseIndex);
        final message = state.messages[index];
        return ChatMessageBubble(
          message: message,
          showRegenerate: !state.isSending && index == lastAssistantIndex,
          onRegenerate: onRegenerate,
        );
      },
    );
  }
}
