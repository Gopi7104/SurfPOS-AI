'use strict';

// Typed error for any failed Surfboard API call — distinguishes "Surfboard's API had a problem"
// from an internal bug, per docs/21_BACKEND_GUIDELINES.md § 9 and docs/07_CODING_RULES.md § 17.
// This is the only error type the Surfboard SDK ever throws — every failure path (network,
// timeout, non-2xx response, or a 2xx response whose own body reports `status: "ERROR"`) is
// normalized into this by errors/errorMapper.js.
//
// `httpStatus` (the transport status code) and `surfboardStatus` (Surfboard's own body-level
// `status` field, e.g. "ERROR") are deliberately separate — Surfboard can report a business
// failure on an HTTP 2xx response (see docs/22_DEVELOPMENT_ROADMAP.md Phase 4 duplicate-detection
// investigation), so the two must never be conflated into one field again.

const { AppError } = require('../../../utils/errors');
const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../../../constants');

class SurfboardApiError extends AppError {
  /**
   * @param {string} [message]
   * @param {{
   *   details?: unknown[], cause?: Error, requestId?: string,
   *   httpStatus?: number, surfboardStatus?: string, surfboardMessage?: string, body?: unknown,
   *   code?: string, statusCode?: number,
   * }} [options]
   */
  constructor(
    message = MESSAGES.SURFBOARD_ERROR,
    {
      details = [],
      cause,
      requestId,
      httpStatus = null,
      surfboardStatus = null,
      surfboardMessage = null,
      body = null,
      code = ERROR_CODES.SURFBOARD_ERROR,
      statusCode = HTTP_STATUS.BAD_GATEWAY,
    } = {},
  ) {
    super(message, { code, statusCode, details });
    this.cause = cause;
    this.requestId = requestId ?? null;
    this.httpStatus = httpStatus;
    this.surfboardStatus = surfboardStatus;
    this.surfboardMessage = surfboardMessage;
    this.body = body;
  }
}

module.exports = SurfboardApiError;
