'use strict';

// Logs the outcome of a Surfboard request — never the body (see docs/21_BACKEND_GUIDELINES.md § 10).

/**
 * @param {{ logger: import('pino').Logger, requestId: string, method: string, path: string, status?: number, durationMs?: number, error?: Error }} args
 */
function logResponse({ logger, requestId, method, path, status, durationMs, error }) {
  if (error) {
    logger?.warn({ surfboardRequestId: requestId, method, path, err: error }, 'Surfboard request failed');
    return;
  }
  logger?.debug(
    { surfboardRequestId: requestId, method, path, status, durationMs },
    'Surfboard request completed',
  );
}

module.exports = { logResponse };
