'use strict';

// Typed error for any failed Surfboard API call — distinguishes "Surfboard's API had a problem"
// from an internal bug, per docs/21_BACKEND_GUIDELINES.md § 9 and docs/07_CODING_RULES.md § 17.
// This is the only error type the Surfboard SDK ever throws — every failure path (network,
// timeout, non-2xx response) is normalized into this by errors/errorMapper.js.

const { AppError } = require('../../../utils/errors');
const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../../../constants');

class SurfboardApiError extends AppError {
  /**
   * @param {string} [message]
   * @param {{ details?: unknown[], cause?: Error, surfboardStatus?: number, requestId?: string }} [options]
   */
  constructor(message = MESSAGES.SURFBOARD_ERROR, { details = [], cause, surfboardStatus, requestId } = {}) {
    super(message, { code: ERROR_CODES.SURFBOARD_ERROR, statusCode: HTTP_STATUS.BAD_GATEWAY, details });
    this.cause = cause;
    this.surfboardStatus = surfboardStatus ?? null;
    this.requestId = requestId ?? null;
  }
}

module.exports = SurfboardApiError;
