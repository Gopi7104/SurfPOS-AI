# modules/ai/

SurfAI — the app's chat assistant, backed by OpenRouter (see docs/16_AI_MODULE.md, docs/22_DEVELOPMENT_ROADMAP.md "Phase AI 1"). `ai.service.js` assembles the system prompt (`prompts/systemPrompt.js`) and current-conversation history, then calls `integrations/openrouter/openrouter.client.js` — the only file that ever makes an HTTP request to OpenRouter, so the API key never leaves the backend.

`models.js` is the single place OpenRouter model IDs are defined — swapping SurfAI's active model is a one-line change there, not a change to this service.

`tools/` holds empty placeholder tool definitions (inventory search, create product, billing lookup, report query, customer lookup) for a future tool-calling phase — none are implemented or registered yet; see each file's header comment and docs/16_AI_MODULE.md "Future Tool Architecture".

OCR invocation and invoice-scanning-specific structuring/product-matching (docs/05_FEATURES.md § 6) are a separate, still-unimplemented future scope — this module only covers SurfAI chat today.
