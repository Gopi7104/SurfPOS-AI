import 'package:surfpos_ai/features/ai/models/ai_chat_reply.dart';
import 'package:surfpos_ai/features/ai/models/ai_model_info.dart';
import 'package:surfpos_ai/features/ai/models/ai_status.dart';
import 'package:surfpos_ai/features/ai/models/chat_message.dart';
import 'package:surfpos_ai/features/ai/repositories/ai_repository.dart';

/// Configurable [AiRepository] test double — mirrors every other fake
/// repository in this app (see `test/features/payments/fakes/`): every
/// method defaults to a harmless behavior, overridable per test via the
/// constructor, never touching the real network.
class FakeAiRepository implements AiRepository {
  FakeAiRepository({
    Future<AiChatReply> Function(List<ChatMessage> history, {String? model})?
        sendMessage,
    Future<AiProviderStatus> Function()? getStatus,
    Future<AiConnectionTestResult> Function()? testConnection,
  })  : _sendMessage = sendMessage ??
            ((history, {model}) async => AiChatReply(
                  message: ChatMessage(
                    id: 'msg_fake',
                    role: ChatRole.assistant,
                    content: 'ok',
                    createdAt: DateTime(2026),
                  ),
                )),
        _getStatus = getStatus ??
            (() async => const AiProviderStatus(
                  provider: 'OpenRouter',
                  activeModel: 'openai/gpt-5-mini',
                  availableModels: [
                    AiModelInfo(
                        id: 'openai/gpt-5-mini',
                        label: 'GPT-5 Mini',
                        provider: 'OpenAI'),
                  ],
                  configured: true,
                )),
        _testConnection = testConnection ??
            (() async => const AiConnectionTestResult(
                connected: true, model: 'openai/gpt-5-mini', latencyMs: 42));

  final Future<AiChatReply> Function(List<ChatMessage> history, {String? model})
      _sendMessage;
  final Future<AiProviderStatus> Function() _getStatus;
  final Future<AiConnectionTestResult> Function() _testConnection;

  @override
  Future<AiChatReply> sendMessage(List<ChatMessage> history, {String? model}) =>
      _sendMessage(history, model: model);

  @override
  Future<AiProviderStatus> getStatus() => _getStatus();

  @override
  Future<AiConnectionTestResult> testConnection() => _testConnection();
}
