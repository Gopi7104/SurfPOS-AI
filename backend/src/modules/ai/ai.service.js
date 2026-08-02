'use strict';

// SurfAI orchestration — the only module that assembles a system prompt + conversation history
// and calls the OpenRouter client. See docs/16_AI_MODULE.md and docs/02_ARCHITECTURE.md § 5.
//
// No tool from tools/ is called here yet (see docs/16_AI_MODULE.md "Future Tool Architecture") —
// this phase is chat-only, per the SurfAI system prompt's own ground rules.

const { ValidationError } = require('../../utils/errors');
const defaultConfig = require('../../config');
const defaultOpenRouterClient = require('../../integrations/openrouter/openrouter.client');
const { SURF_AI_SYSTEM_PROMPT } = require('./prompts/systemPrompt');
const { AVAILABLE_MODELS, ACTIVE_MODEL } = require('./models');

/**
 * @param {{ openRouterClient?: object, config?: object }} [deps]
 */
function createAiService({ openRouterClient = defaultOpenRouterClient, config = defaultConfig } = {}) {
  /**
   * @param {Array<{ role: 'user'|'assistant', content: string }>} messages full conversation so
   *   far, oldest first, ending with the newest user message — the client holds history, not this
   *   service (no chat persistence in Phase AI 1, see docs/16_AI_MODULE.md).
   * @param {{ model?: string }} [options]
   */
  async function sendChatMessage(messages, { model } = {}) {
    if (!messages?.length) {
      throw new ValidationError('At least one message is required');
    }

    const result = await openRouterClient.chatCompletion({
      model: model || ACTIVE_MODEL,
      messages: [{ role: 'system', content: SURF_AI_SYSTEM_PROMPT }, ...messages],
    });

    return {
      message: { role: 'assistant', content: result.content },
      model: result.model,
      finishReason: result.finishReason,
      usage: result.usage,
    };
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
