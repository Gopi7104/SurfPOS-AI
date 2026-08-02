import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/ai/datasources/ai_remote_datasource.dart';
import 'package:surfpos_ai/features/ai/models/chat_message.dart';
import 'package:surfpos_ai/features/ai/repositories/ai_repository_impl.dart';

class _FakeDatasource implements AiRemoteDatasource {
  _FakeDatasource(this._chatResponse);

  final Map<String, dynamic> _chatResponse;

  @override
  Future<Map<String, dynamic>> sendChatMessage(
          List<Map<String, dynamic>> messages,
          {String? model}) async =>
      _chatResponse;

  @override
  Future<Map<String, dynamic>> getStatus() async => {};

  @override
  Future<Map<String, dynamic>> testConnection() async => {};
}

void main() {
  group('AiRepositoryImpl.sendMessage', () {
    test('a tool reply sets toolCategory from reply.tool.name', () async {
      final repository = AiRepositoryImpl(
        datasource: _FakeDatasource({
          'reply': {
            'message': {'role': 'assistant', 'content': '3 products found.'},
            'source': 'tool',
            'tool': {'name': 'inventory', 'function': 'search'},
          },
        }),
      );

      final reply = await repository.sendMessage([]);

      expect(reply.message.content, '3 products found.');
      expect(reply.message.toolCategory, ChatToolCategory.inventory);
      expect(reply.message.role, ChatRole.assistant);
      expect(reply.navigationAction, isNull);
      expect(reply.clientToolRequest, isNull);
    });

    test('an OpenRouter reply (no tool field) leaves toolCategory null',
        () async {
      final repository = AiRepositoryImpl(
        datasource: _FakeDatasource({
          'reply': {
            'message': {'role': 'assistant', 'content': 'Here is some advice.'},
            'source': 'ai',
          },
        }),
      );

      final reply = await repository.sendMessage([]);

      expect(reply.message.toolCategory, isNull);
      expect(reply.navigationAction, isNull);
      expect(reply.clientToolRequest, isNull);
    });

    test('a navigation reply sets navigationAction with its type and params',
        () async {
      final repository = AiRepositoryImpl(
        datasource: _FakeDatasource({
          'reply': {
            'message': {
              'role': 'assistant',
              'content': 'Searching Inventory for "Coca Cola"...'
            },
            'source': 'navigation',
            'action': {
              'type': 'searchInventory',
              'params': {'query': 'Coca Cola'},
            },
          },
        }),
      );

      final reply = await repository.sendMessage([]);

      expect(reply.message.content, 'Searching Inventory for "Coca Cola"...');
      expect(reply.message.toolCategory, isNull);
      expect(reply.navigationAction?.type, 'searchInventory');
      expect(reply.navigationAction?.params, {'query': 'Coca Cola'});
      expect(reply.clientToolRequest, isNull);
    });

    test('a client_tool reply sets clientToolRequest with tool/function/params',
        () async {
      final repository = AiRepositoryImpl(
        datasource: _FakeDatasource({
          'reply': {
            'message': {'role': 'assistant', 'content': ''},
            'source': 'client_tool',
            'tool': {'name': 'dashboard', 'function': 'revenueToday'},
            'params': <String, dynamic>{},
          },
        }),
      );

      final reply = await repository.sendMessage([]);

      expect(reply.message.toolCategory, isNull);
      expect(reply.navigationAction, isNull);
      expect(reply.clientToolRequest?.tool, 'dashboard');
      expect(reply.clientToolRequest?.function, 'revenueToday');
    });
  });
}
