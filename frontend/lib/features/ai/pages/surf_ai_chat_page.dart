import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/glass_header.dart';
import '../../authentication/providers/auth_providers.dart';
import '../controllers/ai_chat_state.dart';
import '../models/chat_message.dart';
import '../providers/ai_providers.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_suggestions.dart';
import '../widgets/chat_typing_indicator.dart';

/// SurfAI's chat screen — reached from Settings' Developer section in
/// Phase AI 1 (see docs/22_DEVELOPMENT_ROADMAP.md "Phase AI 1"; a
/// persistent app-wide entry point, e.g. a bottom-nav tab, is a follow-up
/// decision left to a later phase so this phase stays infrastructure-only).
class SurfAiChatPage extends ConsumerWidget {
  const SurfAiChatPage({super.key});

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
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GlassHeader(
            title: 'SurfAI',
            subtitle: 'Ask anything about your business',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: _ChatBody(
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
    required this.state,
    required this.onSuggestion,
    required this.onRegenerate,
  });

  final AiChatState state;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (state.messages.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ChatSuggestions(onSelect: onSuggestion),
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
          return const ChatTypingBubble();
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
