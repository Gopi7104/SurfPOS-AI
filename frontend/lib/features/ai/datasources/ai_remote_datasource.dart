/// The only layer in this feature allowed to know the `/ai/*` wire shape —
/// [AiRepository] depends on this abstraction, never on [ApiClient]
/// directly (see docs/07_CODING_RULES.md § 3). SurfAI never calls OpenRouter
/// from the client: every method here hits this app's own backend, which
/// is the only thing that ever holds the OpenRouter API key (see
/// docs/16_AI_MODULE.md, docs/02_ARCHITECTURE.md § 5).
abstract class AiRemoteDatasource {
  /// `POST /ai/chat` — `messages` is the full conversation so far (oldest
  /// first), each shaped like `{role, content}`.
  Future<Map<String, dynamic>> sendChatMessage(
    List<Map<String, dynamic>> messages, {
    String? model,
  });

  /// `GET /ai/status` — provider/current-model info only, no live OpenRouter
  /// call.
  Future<Map<String, dynamic>> getStatus();

  /// `POST /ai/status/test` — a real round trip to OpenRouter.
  Future<Map<String, dynamic>> testConnection();
}
