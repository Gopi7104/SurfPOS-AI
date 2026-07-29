'use strict';

// The Surfboard request pipeline's authentication step — resolves the configured
// AuthenticationManager's headers and merges them onto the outgoing request headers. Every
// domain client goes through this via SurfboardBaseClient.request(); no client attaches its own
// auth headers (docs/21_BACKEND_GUIDELINES.md § 5). Replaces the Phase 2 `auth.middleware.js`
// placeholder now that a real, pluggable authentication layer exists (see docs/auth/*).

/**
 * @param {{ headers?: Record<string, string>, authenticationManager?: import('../auth/authenticationManager') }} params
 * @returns {Promise<Record<string, string>>}
 */
async function attachAuthentication({ headers = {}, authenticationManager } = {}) {
  if (!authenticationManager) {
    return headers;
  }
  const authHeaders = await authenticationManager.getAuthHeaders();
  return { ...headers, ...authHeaders };
}

module.exports = { attachAuthentication };
