import '../models/ai_status.dart';
import '../models/chat_message.dart';

abstract class AiRepository {
  /// Sends the full [history] (oldest first, ending with the newest user
  /// message) to SurfAI and returns its assistant reply. Does not mutate
  /// or store [history] itself — [AiChatController] owns the conversation.
  Future<ChatMessage> sendMessage(List<ChatMessage> history, {String? model});

  Future<AiProviderStatus> getStatus();

  Future<AiConnectionTestResult> testConnection();
}
