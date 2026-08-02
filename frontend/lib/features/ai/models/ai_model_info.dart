/// A single OpenRouter model SurfAI could be configured to use — see backend
/// `modules/ai/models.js`, the single place model IDs are defined.
class AiModelInfo {
  const AiModelInfo(
      {required this.id, required this.label, required this.provider});

  factory AiModelInfo.fromJson(Map<String, dynamic> json) => AiModelInfo(
        id: json['id'] as String,
        label: json['label'] as String,
        provider: json['provider'] as String,
      );

  final String id;
  final String label;
  final String provider;
}
