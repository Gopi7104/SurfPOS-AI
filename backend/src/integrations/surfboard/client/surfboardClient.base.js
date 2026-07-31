'use strict';

// Shared foundation for every Surfboard Payments API client — see docs/15_SURFBOARD_INTEGRATION.md.
// Every domain client (auth/merchant/payment/store/device/branding) extends this and calls
// `this.request()` — no client constructs a fetch() call itself. Every call automatically gets
// auth headers, a request ID, retry, timeout, and request/response logging (see
// docs/21_BACKEND_GUIDELINES.md § 5, docs/07_CODING_RULES.md § 17).
//
// Dependencies are injected with real implementations as defaults (docs/21_BACKEND_GUIDELINES.md
// § 12) so tests can substitute a fake `fetchImpl` without a DI container.

const { logger: defaultLogger } = require('../../../utils/logger');
const { resolveSurfboardConfig } = require('./surfboardConfig');
const { withRetry } = require('../middleware/retry.middleware');
const { withTimeout } = require('../middleware/timeout.middleware');
const { attachAuthentication } = require('../middleware/authentication.middleware');
const { logRequest } = require('../middleware/requestLogger.middleware');
const { logResponse } = require('../middleware/responseLogger.middleware');
const { buildRequest } = require('../utils/requestBuilder');
const { parseResponse } = require('../utils/responseParser');
const { generateRequestId } = require('../utils/requestId');
const { mapError, assertSurfboardSuccess } = require('../errors/errorMapper');
const AuthenticationManager = require('../auth/authenticationManager');

class SurfboardBaseClient {
  /**
   * @param {{ config?: object, logger?: import('pino').Logger, fetchImpl?: typeof fetch, authenticationManager?: AuthenticationManager }} [deps]
   */
  constructor({
    config: injectedConfig = resolveSurfboardConfig(),
    logger = defaultLogger,
    fetchImpl = fetch,
    authenticationManager,
  } = {}) {
    this.config = injectedConfig;
    this.logger = logger;
    this.fetchImpl = fetchImpl;
    this._authenticationManager = authenticationManager || null;
  }

  // Lazy — constructing an AuthenticationManager validates credentials (auth/authConfig.js) and
  // must not run at require()/instantiation time, only when a request actually needs auth headers.
  // Requiring/instantiating a domain client (e.g. via its module-level singleton) must not crash
  // process boot just because Surfboard credentials aren't configured yet — same lazy-init
  // principle as firebase/admin.js.
  get authenticationManager() {
    if (!this._authenticationManager) {
      this._authenticationManager = new AuthenticationManager({ config: this.config });
    }
    return this._authenticationManager;
  }

  /**
   * The single request path every domain client method calls through.
   *
   * `expectsEnvelope` opts a call into validating Surfboard's `{ status, data, message }`
   * envelope (docs/08_ARCHITECTURE_DECISIONS.md § ADR-025) — HTTP 2xx alone is not enough,
   * Surfboard can report its own business-level failure inside a 2xx body (confirmed live: an
   * invalid corporate-id returns HTTP 201 with `{status:"ERROR", ...}`). Deliberately opt-in, not
   * automatic for every call: only endpoints *confirmed* to use this envelope should be checked
   * against it — Store's wire format is unconfirmed and reuses `status` for the store's own
   * active/inactive state, which collides with envelope-sniffing by field name alone.
   * @param {import('../models/requestOptions').SurfboardRequestOptions & { expectsEnvelope?: boolean }} options
   * @returns {Promise<import('../models/response').SurfboardResponse>}
   */
  async request({ method, path, query, body, headers, expectsEnvelope = false } = {}) {
    const requestId = generateRequestId();
    const authedHeaders = await attachAuthentication({
      headers: { ...headers, 'X-Request-Id': requestId },
      authenticationManager: this.authenticationManager,
    });
    const { url, init } = buildRequest({
      baseUrl: this.config.baseUrl,
      method,
      path,
      query,
      body,
      headers: authedHeaders,
    });

    logRequest({ logger: this.logger, requestId, method, path });
    const startedAt = Date.now();

    let parsed;
    try {
      const response = await withRetry(
        () => withTimeout((signal) => this.fetchImpl(url, { ...init, signal }), this.config.timeoutMs),
        {
          maxRetries: this.config.maxRetries,
          onRetry: ({ attemptNumber, backoffMs }) =>
            this.logger?.warn(
              { surfboardRequestId: requestId, attemptNumber, backoffMs },
              'Retrying Surfboard request',
            ),
        },
      );
      parsed = await parseResponse(response);
    } catch (error) {
      logResponse({ logger: this.logger, requestId, method, path, error });
      throw mapError(error, { requestId });
    }

    logResponse({
      logger: this.logger,
      requestId,
      method,
      path,
      status: parsed.status,
      durationMs: Date.now() - startedAt,
    });

    if (!parsed.ok) {
      throw mapError({ status: parsed.status, data: parsed.data }, { requestId });
    }

    if (expectsEnvelope) {
      assertSurfboardSuccess(parsed, { requestId });
    }

    return parsed;
  }
}

module.exports = SurfboardBaseClient;
