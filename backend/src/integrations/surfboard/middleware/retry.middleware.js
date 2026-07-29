'use strict';

// Retries a Surfboard request on transient failure — network error, timeout, or a retryable
// HTTP status (408/429/5xx) — with exponential backoff. Never retries a non-retryable status
// (4xx other than 408/429), since that's a request problem retrying can't fix.

const DEFAULT_MAX_RETRIES = 2;
const DEFAULT_BASE_DELAY_MS = 200;
const RETRYABLE_STATUS_CODES = new Set([408, 429, 500, 502, 503, 504]);

function isRetryableError(error) {
  return error?.name === 'AbortError' || error?.code === 'ECONNRESET' || error?.code === 'ETIMEDOUT';
}

function delay(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

/**
 * @param {() => Promise<Response>} attempt
 * @param {{ maxRetries?: number, baseDelayMs?: number, onRetry?: (info: object) => void }} [options]
 */
async function withRetry(
  attempt,
  { maxRetries = DEFAULT_MAX_RETRIES, baseDelayMs = DEFAULT_BASE_DELAY_MS, onRetry } = {},
) {
  for (let attemptNumber = 0; ; attemptNumber += 1) {
    let response;
    let thrownError;

    try {
      response = await attempt();
    } catch (error) {
      thrownError = error;
    }

    const shouldRetry = thrownError
      ? isRetryableError(thrownError)
      : RETRYABLE_STATUS_CODES.has(response.status);

    if (!shouldRetry || attemptNumber === maxRetries) {
      if (thrownError) {
        throw thrownError;
      }
      return response;
    }

    const backoffMs = baseDelayMs * 2 ** attemptNumber;
    onRetry?.({ attemptNumber: attemptNumber + 1, backoffMs, error: thrownError });
    await delay(backoffMs);
  }
}

module.exports = { withRetry, RETRYABLE_STATUS_CODES };
