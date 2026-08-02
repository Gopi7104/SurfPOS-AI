# modules/ai/

SurfAI — the app's chat assistant, backed by OpenRouter for anything its own backend tools can't
answer. `ai.service.js#sendChatMessage` first runs the caller's latest message through
`intent/intentDetector.js` — a fixed, ordered list of keyword/phrase patterns, deliberately NOT
LLM-based — and if it matches, calls the corresponding function in `tools/` directly (a plain
function call, never the LLM) and returns its result without ever reaching OpenRouter. Only when
nothing matches does it assemble the system prompt (`prompts/systemPrompt.js`) + conversation
history and call `integrations/openrouter/openrouter.client.js` — the only file that ever makes an
HTTP request to OpenRouter, so the API key never leaves the backend.

`models.js` is the single place OpenRouter model IDs are defined — swapping SurfAI's active model is a one-line change there, not a change to this service.

`tools/` — real, read-only tool functions per category, registered in `tools/index.js`:

- **inventory.tool.js** — real data, via `modules/inventory/inventory.service.js`.
- **settings.tool.js** — store/merchant info is real (via `modules/merchant/`, `modules/store/`); app version/theme/printer status are honest "not available" replies (those are Flutter/Bluetooth-only concepts, never tracked server-side).
- **billing.tool.js, reports.tool.js, dashboard.tool.js, customer.tool.js** — honest "not available yet" replies for every function. There is no persisted cart, no sales ledger, and no customer records anywhere in this backend yet — these tools exist so intent detection still routes the question here (rather than to OpenRouter, or worse, inventing an answer) instead of silently doing nothing. See each file's header comment for the exact gap.

`tools/tool.interface.js`, `createProduct.tool.js`, and `inventorySearch.tool.js`'s original OpenAI-style function-calling shape are unrelated to the above — that shape is for an LLM to _decide_ when to call a tool, which this phase intentionally does not use (intent detection is plain backend logic). `createProduct.tool.js` stays an unimplemented placeholder — creating a product via chat is out of scope (read-only tools only, no inventory mutations).

OCR invocation and invoice-scanning-specific structuring/product-matching (docs/05_FEATURES.md § 6) are a separate, still-unimplemented future scope — this module only covers SurfAI chat today.
