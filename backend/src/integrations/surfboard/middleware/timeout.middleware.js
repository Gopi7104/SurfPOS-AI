'use strict';

// Aborts a Surfboard request that takes longer than the configured timeout — the abort surfaces
// to the caller as a standard AbortError, which retry.middleware.js and errors/errorMapper.js
// both already know how to handle.

/**
 * @param {(signal: AbortSignal) => Promise<Response>} executeFn
 * @param {number} timeoutMs
 */
async function withTimeout(executeFn, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await executeFn(controller.signal);
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { withTimeout };
