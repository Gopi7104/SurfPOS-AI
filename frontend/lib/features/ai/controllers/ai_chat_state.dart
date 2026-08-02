import '../models/ai_chat_reply.dart';
import '../models/chat_message.dart';

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.isLikelyToolQuery = false,
    this.pendingNavigationAction,
    this.error,
  });

  final List<ChatMessage> messages;

  /// True while waiting on the current `POST /ai/chat` round trip — drives
  /// the typing indicator and disables the send button/regenerate action.
  final bool isSending;

  /// A client-side *guess*, set alongside [isSending], at whether the
  /// outgoing message looks like something SurfPOS's own backend tools could
  /// answer directly — see `AiChatController`'s heuristic. Purely cosmetic:
  /// only chooses which loading label the typing indicator shows ("checking
  /// your business…" vs "thinking…"); actual routing is decided server-side
  /// by `backend/src/modules/ai/intent/intentDetector.js`; this guess can be
  /// wrong without affecting correctness.
  final bool isLikelyToolQuery;

  /// Set right after a `source: 'navigation'` reply — [SurfAiChatPage]
  /// `ref.listen`s for this and performs the actual routing/route push/
  /// provider update (a Riverpod Notifier has no `BuildContext`, so it can't
  /// do that itself), then calls [AiChatController.clearPendingNavigation].
  /// `null` means there's nothing to act on.
  final NavigationAction? pendingNavigationAction;

  /// User-facing text for the last failed send, or null. Backend error
  /// messages are already end-user-safe (see
  /// `core/exceptions/api_exception.dart`'s header comment) — relayed
  /// verbatim, never re-authored here.
  final String? error;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isLikelyToolQuery,
    NavigationAction? pendingNavigationAction,
    bool clearPendingNavigationAction = false,
    String? error,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isLikelyToolQuery: isLikelyToolQuery ?? this.isLikelyToolQuery,
      pendingNavigationAction: clearPendingNavigationAction
          ? null
          : (pendingNavigationAction ?? this.pendingNavigationAction),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
