import '../models/ai_chat_reply.dart';
import '../models/ai_status.dart';
import '../models/chat_message.dart';

abstract class AiRepository {
  /// Sends the full [history] (oldest first, ending with the newest user
  /// message) to SurfAI and returns its reply, plus any navigation/
  /// client-tool metadata the caller (`AiChatController`) needs to act on
  /// — see [AiChatReply]'s header comment. Does not mutate or store
  /// [history] itself — [AiChatController] owns the conversation.
  Future<AiChatReply> sendMessage(List<ChatMessage> history, {String? model});

  Future<AiProviderStatus> getStatus();

  Future<AiConnectionTestResult> testConnection();
}
