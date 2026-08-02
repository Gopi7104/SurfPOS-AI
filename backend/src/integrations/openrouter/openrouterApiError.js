'use strict';

// Typed error for any failed OpenRouter call — distinguishes "the AI provider had a problem" from
// an internal bug, same rationale as integrations/surfboard/errors/surfboardApiError.js. This is
// the only error type openrouter.client.js ever throws; every failure path (missing key, network
// error, timeout, or a non-2xx response) is normalized into this by mapError() below.

const { AppError } = require('../../utils/errors');
const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../../constants');

class OpenRouterApiError extends AppError {
  /**
   * @param {string} [message]
   * @param {{
   *   details?: unknown[], cause?: Error, httpStatus?: number, body?: unknown,
   *   code?: string, statusCode?: number,
   * }} [options]
   */
  constructor(
    message = MESSAGES.AI_PROCESSING_ERROR,
    {
      details = [],
      cause,
      httpStatus = null,
      body = null,
      code = ERROR_CODES.AI_PROCESSING_ERROR,
      statusCode = HTTP_STATUS.BAD_GATEWAY,
    } = {},
  ) {
    super(message, { code, statusCode, details });
    this.cause = cause;
    this.httpStatus = httpStatus;
    this.body = body;
  }
}

/**
 * @param {Error | { status: number, data: * }} error
 */
function mapError(error) {
  if (error instanceof OpenRouterApiError) {
    return error;
  }

  if (error?.name === 'AbortError') {
    return new OpenRouterApiError(MESSAGES.AI_TIMEOUT, { cause: error });
  }

  if (error && typeof error.status === 'number') {
    const body = error.data;
    const upstreamMessage = body && typeof body === 'object' ? (body.error?.message ?? null) : null;

    if (error.status === HTTP_STATUS.TOO_MANY_REQUESTS) {
      return new OpenRouterApiError(MESSAGES.AI_RATE_LIMITED, {
        httpStatus: error.status,
        body,
        details: [body],
        code: ERROR_CODES.RATE_LIMITED,
        statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
      });
    }

    if (error.status === HTTP_STATUS.UNAUTHORIZED || error.status === HTTP_STATUS.FORBIDDEN) {
      // Never relay the upstream message here — it can echo back key/config details. A missing or
      // invalid OPENROUTER_API_KEY is an operator problem, not something the end user caused.
      return new OpenRouterApiError(MESSAGES.AI_NOT_CONFIGURED, {
        httpStatus: error.status,
        body,
        details: [],
      });
    }

    return new OpenRouterApiError(upstreamMessage || MESSAGES.AI_PROCESSING_ERROR, {
      httpStatus: error.status,
      body,
      details: [body],
    });
  }

  return new OpenRouterApiError(MESSAGES.AI_PROCESSING_ERROR, { cause: error });
}

module.exports = { OpenRouterApiError, mapError };
