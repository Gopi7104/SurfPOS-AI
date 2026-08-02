import 'chat_message.dart';

/// A pending client-side navigation command SurfAI's backend detected but
/// can't execute itself — see `backend/src/modules/ai/ai.service.js`'s
/// header comment. [type] matches one of `intent/intentDetector.js`'s
/// `navigation.*` function names exactly (`openBilling`, `searchInventory`,
/// etc.); [params] carries whatever that pattern extracted (e.g.
/// `{query: 'Coca Cola'}` for `searchInventory`).
class NavigationAction {
  const NavigationAction({required this.type, this.params = const {}});

  final String type;
  final Map<String, dynamic> params;
}

/// A backend-detected intent for a category whose real data exists only in
/// this Flutter app — billing (the cart), or dashboard/reports/customer
/// (the Dashboard/Reports/Customers providers and demo data) — see
/// `ClientAiToolExecutor`. [tool]/[function] match
/// `intent/intentDetector.js`'s output exactly.
class ClientToolRequest {
  const ClientToolRequest({
    required this.tool,
    required this.function,
    this.params = const {},
  });

  final String tool;
  final String function;
  final Map<String, dynamic> params;
}

/// What [AiRepository.sendMessage] returns. Exactly one of
/// [navigationAction]/[clientToolRequest] is ever set, matching the
/// backend's `source` field:
/// - `source: 'tool'`/`'ai'` — neither is set; [message] is the real,
///   already-final reply (unchanged from Phase AI-2).
/// - `source: 'navigation'` — [navigationAction] is set; [message] is a
///   short confirmation the backend already wrote (e.g. "Opening
///   Billing..."); the widget performs the actual routing.
/// - `source: 'client_tool'` — [clientToolRequest] is set; [message]'s
///   content is a meaningless placeholder — the controller runs
///   [ClientAiToolExecutor] and builds the real display message itself
///   before this ever reaches the UI.
class AiChatReply {
  const AiChatReply({
    required this.message,
    this.navigationAction,
    this.clientToolRequest,
  });

  final ChatMessage message;
  final NavigationAction? navigationAction;
  final ClientToolRequest? clientToolRequest;
}
