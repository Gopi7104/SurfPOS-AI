/// Who a [ChatMessage] came from — SurfAI's system prompt is assembled
/// server-side (see backend `modules/ai/prompts/systemPrompt.js`) and never
/// appears as a message in this app's own history.
enum ChatRole {
  user,
  assistant;

  String get apiValue => name;
}

/// Delivery state for a single [ChatMessage] — drives the typing indicator
/// and the inline retry affordance on a failed send.
enum ChatMessageStatus { sending, sent, failed }

/// One turn in a SurfAI conversation. Held entirely in memory for the
/// lifetime of [AiChatController] — Phase AI 1 does not persist chat
/// history (see docs/16_AI_MODULE.md).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final ChatMessageStatus status;

  ChatMessage copyWith({String? content, ChatMessageStatus? status}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  /// The shape `POST /ai/chat` expects per history entry — see
  /// `backend/src/validators/ai.validation.js`.
  Map<String, dynamic> toApiJson() =>
      {'role': role.apiValue, 'content': content};
}
