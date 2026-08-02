'use strict';

// The single place OpenRouter model IDs are defined — see docs/16_AI_MODULE.md "Model
// Management". Swapping SurfAI's active model is a one-line change here, never a change to
// ai.service.js/openrouter.client.js. `AVAILABLE_MODELS` is the catalog surfaced to Settings'
// Developer section; `ACTIVE_MODEL` (falling back to config's DEFAULT_MODEL) is the only one
// actually used to serve chat requests today, per "Only one active model for now".

const config = require('../../config');

const AVAILABLE_MODELS = Object.freeze([
  Object.freeze({ id: 'openai/gpt-5-mini', label: 'GPT-5 Mini', provider: 'OpenAI' }),
  Object.freeze({ id: 'anthropic/claude-4-sonnet', label: 'Claude 4 Sonnet', provider: 'Anthropic' }),
  Object.freeze({ id: 'google/gemini-2.5-flash', label: 'Gemini 2.5 Flash', provider: 'Google' }),
  Object.freeze({ id: 'deepseek/deepseek-chat', label: 'DeepSeek Chat', provider: 'DeepSeek' }),
]);

const ACTIVE_MODEL = config.openRouter.defaultModel;

module.exports = { AVAILABLE_MODELS, ACTIVE_MODEL };
