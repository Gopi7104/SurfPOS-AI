'use strict';

// The only file that ever calls the OpenRouter HTTP API — see docs/16_AI_MODULE.md and
// docs/02_ARCHITECTURE.md § 5 ("AI orchestrated only from the backend, never called directly by
// the Flutter client, so the API key stays server-side"). modules/ai/ai.service.js is the only
// caller. Dependencies are injected with real implementations as defaults (same pattern as
// integrations/surfboard/client/surfboardClient.base.js) so tests can substitute a fake
// `fetchImpl` without a DI container.

const { logger: defaultLogger } = require('../../utils/logger');
const { resolveOpenRouterConfig } = require('./openrouter.config');
const { OpenRouterApiError, mapError } = require('./openrouterApiError');
const { MESSAGES } = require('../../constants');

/**
 * @param {{ config?: object, logger?: import('pino').Logger, fetchImpl?: typeof fetch }} [deps]
 */
function createOpenRouterClient({
  config: injectedConfig = resolveOpenRouterConfig(),
  logger = defaultLogger,
  fetchImpl = fetch,
} = {}) {
  /**
   * @param {{ model?: string, messages: Array<{ role: 'system'|'user'|'assistant', content: string }> }} params
   * @returns {Promise<{ content: string, model: string, finishReason: string|null, usage: { promptTokens: number, completionTokens: number, totalTokens: number }|null }>}
   */
  async function chatCompletion({ model, messages }) {
    if (!injectedConfig.apiKey) {
      throw new OpenRouterApiError(MESSAGES.AI_NOT_CONFIGURED);
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), injectedConfig.timeoutMs);

    let response;
    try {
      response = await fetchImpl(`${injectedConfig.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${injectedConfig.apiKey}`,
          'Content-Type': 'application/json',
          // Optional but recommended by OpenRouter for attributing traffic — see
          // https://openrouter.ai/docs. Harmless to omit if unreachable; never required.
          'X-Title': 'SurfPOS AI',
        },
        body: JSON.stringify({
          model: model || injectedConfig.defaultModel,
          messages,
          stream: false,
        }),
        signal: controller.signal,
      });
    } catch (error) {
      logger.warn({ err: error }, 'OpenRouter request failed before a response was received');
      throw mapError(error);
    } finally {
      clearTimeout(timeout);
    }

    const body = await response.json().catch(() => null);

    if (!response.ok) {
      logger.warn({ status: response.status, body }, 'OpenRouter returned a non-2xx response');
      throw mapError({ status: response.status, data: body });
    }

    const choice = body?.choices?.[0];
    const content = choice?.message?.content;
    if (typeof content !== 'string' || content.length === 0) {
      throw new OpenRouterApiError(MESSAGES.AI_PROCESSING_ERROR, { body });
    }

    return {
      content,
      model: body.model || model || injectedConfig.defaultModel,
      finishReason: choice.finish_reason ?? null,
      usage: body.usage
        ? {
            promptTokens: body.usage.prompt_tokens ?? 0,
            completionTokens: body.usage.completion_tokens ?? 0,
            totalTokens: body.usage.total_tokens ?? 0,
          }
        : null,
    };
  }

  return { chatCompletion };
}

module.exports = createOpenRouterClient();
module.exports.createOpenRouterClient = createOpenRouterClient;
