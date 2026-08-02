import '../../../core/network/api_client.dart';
import 'ai_remote_datasource.dart';

class AiRemoteDatasourceImpl implements AiRemoteDatasource {
  AiRemoteDatasourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Map<String, dynamic>> sendChatMessage(
    List<Map<String, dynamic>> messages, {
    String? model,
  }) {
    return _apiClient.post(
      '/ai/chat',
      requiresAuth: true,
      body: {
        'messages': messages,
        if (model != null) 'model': model,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getStatus() =>
      _apiClient.get('/ai/status', requiresAuth: true);

  @override
  Future<Map<String, dynamic>> testConnection() =>
      _apiClient.post('/ai/status/test', requiresAuth: true);
}
