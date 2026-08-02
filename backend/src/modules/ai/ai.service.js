'use strict';

// SurfAI orchestration — the only module that assembles a system prompt + conversation history
// and calls the OpenRouter client. See docs/16_AI_MODULE.md and docs/02_ARCHITECTURE.md § 5.
//
// Phase AI-2 (tool calling): before ever calling OpenRouter, `sendChatMessage` checks the latest
// user message against intent/intentDetector.js's lightweight backend patterns. A match runs the
// matching function in tools/ directly (plain function call, never the LLM) and returns its
// result — OpenRouter is only consulted when nothing matches, so a question the backend can
// already answer never costs a token.
//
// Phase AI-3 adds two more intent outcomes, both *detected* here but *executed* entirely on the
// frontend, since neither has anything this Node backend can act on:
//   - `tool: 'navigation'` — a page-switch/search/demo-data command. Returns `source: 'navigation'`
//     with a short confirmation message and the action to perform; the client
//     (`ai_chat_controller.dart`) does the actual routing.
//   - `tool` in CLIENT_EXECUTED_TOOLS (billing/dashboard/reports/customer) — that category's real
//     data lives only in Flutter (the cart, and the Dashboard/Reports/Customers providers/demo
//     data) — this backend has no sales ledger or customer records to answer from (confirmed in
//     Phase AI-2). Returns `source: 'client_tool'` with no message content; the client reads its
//     own providers (via `ClientAiToolExecutor`) and builds the real reply itself.
// Only `inventory`/`settings` still resolve here, via tools/index.js, exactly as in Phase AI-2.

const { ValidationError } = require('../../utils/errors');
const { logger: defaultLogger } = require('../../utils/logger');
const defaultConfig = require('../../config');
const defaultOpenRouterClient = require('../../integrations/openrouter/openrouter.client');
const { SURF_AI_SYSTEM_PROMPT } = require('./prompts/systemPrompt');
const { AVAILABLE_MODELS, ACTIVE_MODEL } = require('./models');
const { detectIntent: defaultDetectIntent } = require('./intent/intentDetector');
const defaultToolRegistry = require('./tools');

const TOOL_FAILURE_MESSAGE = 'I ran into a problem looking that up — please try again in a moment.';

const CLIENT_EXECUTED_TOOLS = new Set(['billing', 'dashboard', 'reports', 'customer']);

const NAVIGATION_MESSAGES = {
  openBilling: 'Opening Billing...',
  openInventory: 'Opening Inventory...',
  openReports: 'Opening Reports...',
  openCustomers: 'Opening Customers...',
  openSettings: 'Opening Settings...',
  openDashboard: 'Opening Dashboard...',
  openAddProduct: 'Opening Add Product...',
  startNewSale: 'Starting a new sale...',
  generateDemoData: 'Generating demo business data...',
  searchInventory: (params) => `Searching Inventory for "${params.query ?? ''}"...`,
};

/**
 * @param {{ openRouterClient?: object, config?: object, detectIntent?: Function, toolRegistry?: object, logger?: object }} [deps]
 */
function createAiService({
  openRouterClient = defaultOpenRouterClient,
  config = defaultConfig,
  detectIntent = defaultDetectIntent,
  toolRegistry = defaultToolRegistry,
  logger = defaultLogger,
} = {}) {
  function lastUserMessage(messages) {
    for (let i = messages.length - 1; i >= 0; i -= 1) {
      if (messages[i].role === 'user') return messages[i].content;
    }
    return null;
  }

  function navigationReply(intent) {
    const messageOrFn = NAVIGATION_MESSAGES[intent.function];
    const content = typeof messageOrFn === 'function' ? messageOrFn(intent.params) : messageOrFn;
    return {
      message: { role: 'assistant', content: content ?? 'On it...' },
      model: null,
      finishReason: 'navigation',
      usage: null,
      source: 'navigation',
      action: { type: intent.function, params: intent.params },
    };
  }

  function clientToolReply(intent) {
    return {
      message: { role: 'assistant', content: '' },
      model: null,
      finishReason: 'client_tool',
      usage: null,
      source: 'client_tool',
      tool: { name: intent.tool, function: intent.function },
      params: intent.params,
    };
  }

  async function runTool(intent, uid) {
    try {
      const result = await toolRegistry.executeTool(intent, uid);
      return {
        message: { role: 'assistant', content: result.message },
        model: null,
        finishReason: 'tool',
        usage: null,
        source: 'tool',
        tool: { name: intent.tool, function: intent.function },
      };
    } catch (error) {
      logger.error(
        { err: error, tool: intent.tool, function: intent.function },
        'SurfAI tool execution failed',
      );
      return {
        message: { role: 'assistant', content: TOOL_FAILURE_MESSAGE },
        model: null,
        finishReason: 'tool',
        usage: null,
        source: 'tool',
        tool: { name: intent.tool, function: intent.function },
      };
    }
  }

  async function askOpenRouter(messages, model) {
    const result = await openRouterClient.chatCompletion({
      model: model || ACTIVE_MODEL,
      messages: [{ role: 'system', content: SURF_AI_SYSTEM_PROMPT }, ...messages],
    });

    return {
      message: { role: 'assistant', content: result.content },
      model: result.model,
      finishReason: result.finishReason,
      usage: result.usage,
      source: 'ai',
    };
  }

  /**
   * @param {Array<{ role: 'user'|'assistant', content: string }>} messages full conversation so
   *   far, oldest first, ending with the newest user message — the client holds history, not this
   *   service (no chat persistence in Phase AI 1, see docs/16_AI_MODULE.md).
   * @param {{ model?: string, uid?: string }} [options] `uid` is required for a backend tool to
   *   run (it's how each tool resolves the caller's own store/merchant) — omitting it just means
   *   every message goes straight to OpenRouter, same as before Phase AI-2.
   */
  async function sendChatMessage(messages, { model, uid } = {}) {
    if (!messages?.length) {
      throw new ValidationError('At least one message is required');
    }

    const intent = uid ? detectIntent(lastUserMessage(messages)) : null;
    if (intent?.tool === 'navigation') {
      return navigationReply(intent);
    }
    if (intent && CLIENT_EXECUTED_TOOLS.has(intent.tool)) {
      return clientToolReply(intent);
    }
    if (intent) {
      return runTool(intent, uid);
    }

    return askOpenRouter(messages, model);
  }

  /**
   * @returns {{ activeModel: string, availableModels: Array<{ id: string, label: string, provider: string }>, configured: boolean }}
   */
  function getModelInfo() {
    return {
      activeModel: ACTIVE_MODEL,
      availableModels: AVAILABLE_MODELS,
      configured: Boolean(config.openRouter.apiKey),
    };
  }

  /**
   * A real, minimal round trip to OpenRouter — used by Settings' Developer "Connection Test", not
   * called on every status check (see controllers/ai.controller.js). Never throws — every failure
   * (missing key, timeout, upstream error) is reported in the returned shape instead, since this
   * exists specifically to surface that failure to the merchant.
   * @returns {Promise<{ connected: boolean, model: string, latencyMs: number|null, error: string|null }>}
   */
  async function testConnection() {
    const startedAt = Date.now();
    try {
      await openRouterClient.chatCompletion({
        model: ACTIVE_MODEL,
        messages: [
          { role: 'system', content: 'Reply with exactly one word: OK.' },
          { role: 'user', content: 'ping' },
        ],
      });
      return { connected: true, model: ACTIVE_MODEL, latencyMs: Date.now() - startedAt, error: null };
    } catch (error) {
      return {
        connected: false,
        model: ACTIVE_MODEL,
        latencyMs: null,
        error: error.message || 'Connection test failed',
      };
    }
  }

  return { sendChatMessage, getModelInfo, testConnection };
}

module.exports = createAiService();
module.exports.createAiService = createAiService;
