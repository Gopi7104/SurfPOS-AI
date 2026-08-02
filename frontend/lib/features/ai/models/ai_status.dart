import 'ai_model_info.dart';

/// `GET /ai/status` — read on Settings' Developer section without making a
/// real OpenRouter call (see [AiConnectionTestResult] for the one that
/// does).
class AiProviderStatus {
  const AiProviderStatus({
    required this.provider,
    required this.activeModel,
    required this.availableModels,
    required this.configured,
  });

  factory AiProviderStatus.fromJson(Map<String, dynamic> json) =>
      AiProviderStatus(
        provider: json['provider'] as String,
        activeModel: json['activeModel'] as String,
        availableModels: (json['availableModels'] as List<dynamic>)
            .map((model) => AiModelInfo.fromJson(model as Map<String, dynamic>))
            .toList(),
        configured: json['configured'] as bool,
      );

  final String provider;
  final String activeModel;
  final List<AiModelInfo> availableModels;

  /// Whether the backend has an `OPENROUTER_API_KEY` set — not whether it
  /// actually works; see [AiConnectionTestResult] for a real round trip.
  final bool configured;
}

/// `POST /ai/status/test` — a real, minimal round trip to OpenRouter,
/// triggered only by Settings' "Test Connection" button, never
/// automatically (see `backend/src/modules/ai/ai.service.js#testConnection`).
class AiConnectionTestResult {
  const AiConnectionTestResult({
    required this.connected,
    required this.model,
    this.latencyMs,
    this.error,
  });

  factory AiConnectionTestResult.fromJson(Map<String, dynamic> json) =>
      AiConnectionTestResult(
        connected: json['connected'] as bool,
        model: json['model'] as String,
        latencyMs: json['latencyMs'] as int?,
        error: json['error'] as String?,
      );

  final bool connected;
  final String model;
  final int? latencyMs;
  final String? error;
}
