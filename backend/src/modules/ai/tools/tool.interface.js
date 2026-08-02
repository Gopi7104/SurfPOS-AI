'use strict';

// Shape every future SurfAI tool will implement (see docs/16_AI_MODULE.md "Future Tool
// Architecture"). Not wired up anywhere yet — no service constructs or calls a tool, and no tool
// is registered with ai.service.js. This exists purely so every placeholder tool in this folder
// implements the same contract from day one, instead of each one inventing its own shape when
// tool-calling is actually built (Phase AI 2+).
//
// `parameters` is a JSON-Schema-shaped object describing the arguments the tool accepts — the
// same shape an OpenRouter/OpenAI-style function-calling `tools[]` entry expects — so wiring this
// into the chat request later is additive, not a redesign.

/**
 * @typedef {{
 *   name: string,
 *   description: string,
 *   parameters: object,
 *   execute: (args: object, context: { uid: string }) => Promise<unknown>,
 * }} AiTool
 */

/**
 * @param {string} name
 * @returns {(args: object, context: { uid: string }) => Promise<never>}
 */
function notImplemented(name) {
  return async () => {
    throw new Error(`AiTool "${name}" is not implemented yet — see docs/16_AI_MODULE.md`);
  };
}

module.exports = { notImplemented };
