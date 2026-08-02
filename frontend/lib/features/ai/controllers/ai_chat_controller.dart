import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/api_exception.dart';
import '../models/chat_message.dart';
import '../providers/ai_providers.dart';
import '../services/client_ai_tool_executor.dart';
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
      isLikelyToolQuery: _looksLikeToolQuery(trimmed),
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

    final lastUserContent = history.reversed
        .firstWhere((m) => m.role == ChatRole.user, orElse: () => history.last)
        .content;
    state = state.copyWith(
      messages: history,
      isSending: true,
      isLikelyToolQuery: _looksLikeToolQuery(lastUserContent),
      clearError: true,
    );
    await _requestReply();
  }

  /// A coarse, client-only guess at whether [text] is something SurfPOS's
  /// own backend tools could answer directly — used only to pick a loading
  /// label (see [AiChatState.isLikelyToolQuery]'s header comment). Kept
  /// deliberately looser than the backend's real
  /// `intent/intentDetector.js` patterns; being wrong here never changes
  /// what answer the user gets, only which loading text they briefly see.
  static bool _looksLikeToolQuery(String text) {
    const keywords = [
      'stock',
      'inventory',
      'product',
      'barcode',
      'category',
      'sales',
      'revenue',
      'best sell',
      'top category',
      'average order',
      'orders today',
      'business insight',
      'growth',
      'quick stat',
      'kpi',
      'customer',
      'cart',
      'item count',
      'discount',
      'tax',
      'grand total',
      'merchant',
      'store info',
      'app version',
      'theme',
      'printer',
      'open ',
      'new sale',
      'search ',
      'generate demo',
    ];
    final lower = text.toLowerCase();
    return keywords.any(lower.contains);
  }

  void dismissError() => state = state.copyWith(clearError: true);

  /// Called by [SurfAiChatPage] once it's finished acting on
  /// [AiChatState.pendingNavigationAction] (switched tabs, pushed a route,
  /// etc.) — resets it so the same action never re-fires on a later rebuild.
  void clearPendingNavigation() =>
      state = state.copyWith(clearPendingNavigationAction: true);

  Future<void> _requestReply() async {
    try {
      final reply =
          await ref.read(aiRepositoryProvider).sendMessage(state.messages);

      final clientToolRequest = reply.clientToolRequest;
      if (clientToolRequest != null) {
        // Runs entirely client-side (reads the same providers the
        // Billing/Dashboard/Reports/Customers pages use) — the backend never
        // produced real content for this reply, see AiChatReply's header
        // comment.
        final content =
            await ClientAiToolExecutor(ref).execute(arg, clientToolRequest);
        final message = ChatMessage(
          id: reply.message.id,
          role: reply.message.role,
          content: content,
          createdAt: reply.message.createdAt,
          toolCategory: ChatToolCategory.fromApiValue(clientToolRequest.tool),
        );
        state = state
            .copyWith(messages: [...state.messages, message], isSending: false);
        return;
      }

      state = state.copyWith(
        messages: [...state.messages, reply.message],
        isSending: false,
        pendingNavigationAction: reply.navigationAction,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isSending: false, error: error.message);
    }
  }

  String _newId() => 'msg_${DateTime.now().microsecondsSinceEpoch}';
}
