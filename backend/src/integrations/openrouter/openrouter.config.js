'use strict';

// Resolves OpenRouter configuration from backend env config — the only place SurfAI's provider
// settings (base URL, key, default model, timeout) are decided. See docs/16_AI_MODULE.md.

const config = require('../../config');

const DEFAULT_TIMEOUT_MS = 30_000;

/**
 * @returns {{ apiKey?: string, baseUrl: string, defaultModel: string, timeoutMs: number }}
 */
function resolveOpenRouterConfig() {
  return {
    apiKey: config.openRouter.apiKey,
    baseUrl: config.openRouter.baseUrl,
    defaultModel: config.openRouter.defaultModel,
    timeoutMs: DEFAULT_TIMEOUT_MS,
  };
}

module.exports = { resolveOpenRouterConfig, DEFAULT_TIMEOUT_MS };
