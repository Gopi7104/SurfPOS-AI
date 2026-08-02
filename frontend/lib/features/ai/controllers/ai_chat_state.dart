import '../models/chat_message.dart';

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;

  /// True while waiting on the current `POST /ai/chat` round trip — drives
  /// the typing indicator and disables the send button/regenerate action.
  final bool isSending;

  /// User-facing text for the last failed send, or null. Backend error
  /// messages are already end-user-safe (see
  /// `core/exceptions/api_exception.dart`'s header comment) — relayed
  /// verbatim, never re-authored here.
  final String? error;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
