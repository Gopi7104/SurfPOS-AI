'use strict';

// The tool registry `ai.service.js` dispatches through once intent/intentDetector.js has matched
// a message to `inventory`/`settings` — the only two categories this backend can actually answer
// (see ai.service.js's header comment). Maps `{tool, function}` to the actual async function to
// call; every tool function takes `(uid, params)` and returns `{ available: boolean, message:
// string }`.
//
// billing/dashboard/reports/customer are NOT registered here as of Phase AI-3 — that data lives
// only in the Flutter app (the cart, and the Dashboard/Reports/Customers providers/demo data), so
// `ai.service.js` intercepts those categories before ever reaching this registry and hands them to
// the client instead (`source: 'client_tool'`) — see `frontend/lib/features/ai/services/client_ai_tool_executor.dart`.
//
// Deliberately NOT the OpenAI/OpenRouter `tools[]` function-calling shape (see tool.interface.js)
// — intent detection here is plain backend logic, never delegated to the LLM, so there is no
// `parameters` JSON-Schema or `tool_choice` protocol to satisfy; a tool is just a function.

const defaultInventoryTool = require('./inventory.tool');
const defaultSettingsTool = require('./settings.tool');

/**
 * @param {{ inventoryTool?, settingsTool? }} [deps]
 */
function createToolRegistry({
  inventoryTool = defaultInventoryTool,
  settingsTool = defaultSettingsTool,
} = {}) {
  const registry = {
    inventory: inventoryTool,
    settings: settingsTool,
  };

  /**
   * @param {{ tool: string, function: string, params: object }} intent from detectIntent()
   * @param {string} uid
   * @returns {Promise<{ available: boolean, message: string }>}
   */
  async function executeTool(intent, uid) {
    const fn = registry[intent.tool]?.[intent.function];
    if (typeof fn !== 'function') {
      throw new Error(`Unknown AI tool "${intent.tool}.${intent.function}"`);
    }
    return fn(uid, intent.params);
  }

  return { executeTool };
}

module.exports = createToolRegistry();
module.exports.createToolRegistry = createToolRegistry;
