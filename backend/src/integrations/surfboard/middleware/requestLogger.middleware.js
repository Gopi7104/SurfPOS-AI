'use strict';

// Logs an outgoing Surfboard request — never the body (see docs/21_BACKEND_GUIDELINES.md § 10).

/**
 * @param {{ logger: import('pino').Logger, requestId: string, method: string, path: string }} args
 */
function logRequest({ logger, requestId, method, path }) {
  logger?.debug({ surfboardRequestId: requestId, method, path }, 'Surfboard request started');
}

module.exports = { logRequest };
