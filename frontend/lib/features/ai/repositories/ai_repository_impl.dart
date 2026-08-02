import '../datasources/ai_remote_datasource.dart';
import '../models/ai_chat_reply.dart';
import '../models/ai_status.dart';
import '../models/chat_message.dart';
import 'ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl({required AiRemoteDatasource datasource})
      : _datasource = datasource;

  final AiRemoteDatasource _datasource;

  @override
  Future<AiChatReply> sendMessage(List<ChatMessage> history,
      {String? model}) async {
    final data = await _datasource.sendChatMessage(
      history.map((message) => message.toApiJson()).toList(),
      model: model,
    );
    final reply = data['reply'] as Map<String, dynamic>;
    final rawMessage = reply['message'] as Map<String, dynamic>;
    final source = reply['source'] as String?;
    // `tool` is only present when `source == 'tool'`/`'client_tool'` — absent for `'navigation'`/
    // `'ai'`, so `toolCategory` naturally stays null for those (see ai.service.js).
    final tool = reply['tool'] as Map<String, dynamic>?;

    final message = ChatMessage(
      id: _newId(),
      role: ChatRole.assistant,
      content: rawMessage['content'] as String,
      createdAt: DateTime.now(),
      toolCategory: source == 'tool'
          ? ChatToolCategory.fromApiValue(tool?['name'] as String?)
          : null,
    );

    if (source == 'navigation') {
      final action = reply['action'] as Map<String, dynamic>;
      return AiChatReply(
        message: message,
        navigationAction: NavigationAction(
          type: action['type'] as String,
          params: (action['params'] as Map<String, dynamic>?) ?? const {},
        ),
      );
    }

    if (source == 'client_tool') {
      return AiChatReply(
        message: message,
        clientToolRequest: ClientToolRequest(
          tool: tool!['name'] as String,
          function: tool['function'] as String,
          params: (reply['params'] as Map<String, dynamic>?) ?? const {},
        ),
      );
    }

    return AiChatReply(message: message);
  }

  @override
  Future<AiProviderStatus> getStatus() async {
    final data = await _datasource.getStatus();
    return AiProviderStatus.fromJson(data);
  }

  @override
  Future<AiConnectionTestResult> testConnection() async {
    final data = await _datasource.testConnection();
    return AiConnectionTestResult.fromJson(data);
  }

  String _newId() => 'msg_${DateTime.now().microsecondsSinceEpoch}';
}
