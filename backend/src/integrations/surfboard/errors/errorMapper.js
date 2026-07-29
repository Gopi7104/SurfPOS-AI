'use strict';

// Normalizes every possible Surfboard call failure — network error, timeout, non-2xx response —
// into a single SurfboardApiError, so nothing above the SDK ever has to branch on failure shape.

const SurfboardApiError = require('./surfboardApiError');
const { MESSAGES } = require('../../../constants');

/**
 * @param {Error | { status: number, data: * }} error
 * @param {{ requestId?: string }} [context]
 */
function mapError(error, { requestId } = {}) {
  if (error instanceof SurfboardApiError) {
    return error;
  }

  if (error?.name === 'AbortError') {
    return new SurfboardApiError(MESSAGES.SURFBOARD_TIMEOUT, { cause: error, requestId });
  }

  if (error && typeof error.status === 'number') {
    const message = (error.data && (error.data.message || error.data.error)) || MESSAGES.SURFBOARD_ERROR;
    return new SurfboardApiError(message, {
      surfboardStatus: error.status,
      details: [error.data],
      requestId,
    });
  }

  return new SurfboardApiError(MESSAGES.SURFBOARD_ERROR, { cause: error, requestId });
}

module.exports = { mapError };
