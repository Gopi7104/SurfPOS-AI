import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/api_exception.dart';
import '../models/chat_message.dart';
import '../providers/ai_providers.dart';
import 'ai_chat_state.dart';

/// One SurfAI conversation for exactly one Firebase uid (see
/// [aiChatControllerProvider] — a `.family` provider) — never a global
/// singleton, matching every other per-user controller in this app (e.g.
/// `features/billing/controllers/billing_controller.dart`).
///
/// In-memory only — Phase AI 1 does not persist chat history (see
/// docs/16_AI_MODULE.md); switching accounts or restarting the app starts a
/// fresh conversation.
class AiChatController extends AutoDisposeFamilyNotifier<AiChatState, String> {
  @override
  AiChatState build(String uid) => const AiChatState();

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatMessage(
      id: _newId(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );

    await _requestReply();
  }

  /// Drops the last assistant reply (if any) and re-asks with the same
  /// history — "Regenerate response" on the last message.
  Future<void> regenerateLast() async {
    if (state.isSending || state.messages.isEmpty) return;

    final history = [...state.messages];
    if (history.last.role == ChatRole.assistant) {
      history.removeLast();
    }
    if (history.isEmpty) return;

    state =
        state.copyWith(messages: history, isSending: true, clearError: true);
    await _requestReply();
  }

  void dismissError() => state = state.copyWith(clearError: true);

  Future<void> _requestReply() async {
    try {
      final reply =
          await ref.read(aiRepositoryProvider).sendMessage(state.messages);
      state = state
          .copyWith(messages: [...state.messages, reply], isSending: false);
    } on ApiException catch (error) {
      state = state.copyWith(isSending: false, error: error.message);
    }
  }

  String _newId() => 'msg_${DateTime.now().microsecondsSinceEpoch}';
}
