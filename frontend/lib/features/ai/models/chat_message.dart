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

/// Which backend tool category (if any) answered this message — see
/// `backend/src/modules/ai/tools/`. `null` means a plain message: either the
/// user's own text, or an assistant reply that came from OpenRouter rather
/// than a backend tool (Phase AI-2, see `backend/src/modules/ai/ai.service.js`).
/// Drives [ChatMessageBubble]'s "tool result" card styling — never changes
/// what the message says, only how it's presented.
enum ChatToolCategory {
  inventory,
  billing,
  reports,
  dashboard,
  customer,
  settings;

  static ChatToolCategory? fromApiValue(String? value) {
    for (final category in values) {
      if (category.name == value) return category;
    }
    return null;
  }
}

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
    this.toolCategory,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final ChatMessageStatus status;

  /// Set only on an assistant message that a backend tool answered (see
  /// `AiRepositoryImpl.sendMessage`, which reads the reply's `source`/`tool`
  /// fields) — always `null` for a user message or an OpenRouter reply.
  final ChatToolCategory? toolCategory;

  ChatMessage copyWith({String? content, ChatMessageStatus? status}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      toolCategory: toolCategory,
    );
  }

  /// The shape `POST /ai/chat` expects per history entry — see
  /// `backend/src/validators/ai.validation.js`. Tool-category metadata is a
  /// display-only concern and is never sent back to the backend.
  Map<String, dynamic> toApiJson() =>
      {'role': role.apiValue, 'content': content};
}
