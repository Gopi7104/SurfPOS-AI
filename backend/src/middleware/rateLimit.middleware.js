'use strict';

// Global request rate limiter — see docs/04_API_DOCUMENTATION.md § 12 (default: 120 req/min).
// Per-route stricter limits (e.g. AI-backed endpoints) are added alongside those routes when
// they're built, reusing this same factory rather than a second ad hoc limiter.

const rateLimit = require('express-rate-limit');
const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../constants');
const { sendError } = require('../utils/response');

const DEFAULT_WINDOW_MS = 60 * 1000;
const DEFAULT_MAX_REQUESTS = 120;

/**
 * @param {{ windowMs?: number, max?: number }} [options]
 */
function createRateLimiter({ windowMs = DEFAULT_WINDOW_MS, max = DEFAULT_MAX_REQUESTS } = {}) {
  return rateLimit({
    windowMs,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      sendError(res, {
        code: ERROR_CODES.RATE_LIMITED,
        message: MESSAGES.RATE_LIMITED,
        statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
      });
    },
  });
}

module.exports = { createRateLimiter };
