'use strict';

// Normalizes every possible Surfboard call failure — network error, timeout, non-2xx response, or
// a 2xx response whose own body reports `status: "ERROR"` — into a single SurfboardApiError, so
// nothing above the SDK ever has to branch on failure shape.

const SurfboardApiError = require('./surfboardApiError');
const { MESSAGES, ERROR_CODES, HTTP_STATUS } = require('../../../constants');

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
    const body = error.data;
    const surfboardStatus = body && typeof body === 'object' ? (body.status ?? null) : null;
    const surfboardMessage = body && typeof body === 'object' ? (body.message ?? body.error ?? null) : null;
    return new SurfboardApiError(surfboardMessage || MESSAGES.SURFBOARD_ERROR, {
      httpStatus: error.status,
      surfboardStatus,
      surfboardMessage,
      body: body ?? null,
      details: [body],
      requestId,
    });
  }

  return new SurfboardApiError(MESSAGES.SURFBOARD_ERROR, { cause: error, requestId });
}

/**
 * Every confirmed Surfboard Merchant/Store endpoint shares the `{ status, data, message }`
 * envelope (docs/08_ARCHITECTURE_DECISIONS.md § ADR-025) — but transport-level success (HTTP 2xx)
 * says nothing about whether Surfboard itself considers the request successful. Surfboard can, and
 * does, answer with an HTTP 201/200 while its own body reports `status: "ERROR"` (confirmed live:
 * an invalid corporate-id returns HTTP 201 with `{status:"ERROR", message:"Invalid swedish
 * corporate-id length."}`). Never trust HTTP status alone for an enveloped response — call this
 * right after any successful `parsed.ok` check, for every domain client, not only Merchant.
 *
 * A response with no `status` key at all doesn't use this envelope (e.g. Store's wire format is
 * unconfirmed, see store.client.js) — nothing to validate, so it's left alone.
 *
 * @param {{ status: number, data: * }} parsed the base client's parsed HTTP response
 * @param {{ requestId?: string }} [context]
 */
function assertSurfboardSuccess(parsed, { requestId } = {}) {
  const body = parsed?.data;
  const isEnvelope = body !== null && typeof body === 'object' && !Array.isArray(body) && 'status' in body;
  if (!isEnvelope) {
    return;
  }

  if (body.status !== 'SUCCESS') {
    throw new SurfboardApiError(body.message || MESSAGES.SURFBOARD_ERROR, {
      httpStatus: parsed.status,
      surfboardStatus: body.status ?? null,
      surfboardMessage: body.message ?? null,
      body,
      details: [body],
      requestId,
      // Surfboard already returned HTTP 2xx here — a business-level rejection of the request's own
      // data (e.g. a malformed corporate id), not an upstream/credential failure. Safe, and useful,
      // to relay verbatim to the caller — unlike the generic 502 SURFBOARD_ERROR path (used for
      // non-2xx/timeout failures), which deliberately never reaches the end user verbatim.
      code: ERROR_CODES.VALIDATION_ERROR,
      statusCode: HTTP_STATUS.BAD_REQUEST,
    });
  }
}

module.exports = { mapError, assertSurfboardSuccess };
