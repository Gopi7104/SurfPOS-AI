'use strict';

// Single structured logger instance for the whole backend — see docs/07_CODING_RULES.md § 9.
// Reads LOG_LEVEL/NODE_ENV directly from process.env (not src/config) so it can be constructed
// before config validation runs and used to report config problems themselves.

const pino = require('pino');

const isProduction = process.env.NODE_ENV === 'production';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: { service: 'surfpos-ai-backend' },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: ['req.headers.authorization'],
  transport: isProduction
    ? undefined
    : { target: 'pino-pretty', options: { colorize: true, translateTime: 'SYS:standard' } },
});

/**
 * @param {{ requestId?: string, merchantId?: string }} context
 * @returns {import('pino').Logger} a child logger carrying the given context on every line
 */
function createRequestLogger(context) {
  return logger.child(context);
}

module.exports = { logger, createRequestLogger };
