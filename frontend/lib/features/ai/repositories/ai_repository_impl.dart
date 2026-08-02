import '../datasources/ai_remote_datasource.dart';
import '../models/ai_status.dart';
import '../models/chat_message.dart';
import 'ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl({required AiRemoteDatasource datasource})
      : _datasource = datasource;

  final AiRemoteDatasource _datasource;

  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> history,
      {String? model}) async {
    final data = await _datasource.sendChatMessage(
      history.map((message) => message.toApiJson()).toList(),
      model: model,
    );
    final reply = data['reply'] as Map<String, dynamic>;
    final message = reply['message'] as Map<String, dynamic>;

    return ChatMessage(
      id: _newId(),
      role: ChatRole.assistant,
      content: message['content'] as String,
      createdAt: DateTime.now(),
    );
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
