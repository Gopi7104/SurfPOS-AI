'use strict';

// Verifies the Firebase ID token on every protected route — see docs/02_ARCHITECTURE.md § 11.
// A valid token proves identity only; each controller still re-checks the authenticated user's
// merchantId/storeId/role ownership of the resource being accessed (docs/07_CODING_RULES.md § 11).
// Token verification itself is owned by modules/auth/auth.service.js so there's exactly one
// implementation, shared with POST /auth/login (docs/21_BACKEND_GUIDELINES.md § 8).

const { UnauthenticatedError } = require('../utils/errors');
const { MESSAGES } = require('../constants');
const asyncHandler = require('../utils/asyncHandler');
const defaultAuthService = require('../modules/auth/auth.service');

const BEARER_PREFIX = 'Bearer ';

function extractToken(req) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith(BEARER_PREFIX)) {
    return null;
  }
  return header.slice(BEARER_PREFIX.length).trim();
}

/**
 * @param {{ authService?: object }} [deps]
 */
function createAuthMiddleware({ authService = defaultAuthService } = {}) {
  const authenticate = asyncHandler(async (req, res, next) => {
    const token = extractToken(req);
    if (!token) {
      throw new UnauthenticatedError(MESSAGES.MISSING_TOKEN);
    }

    let decodedToken;
    try {
      decodedToken = await authService.verifyToken(token);
    } catch (error) {
      req.log?.warn({ err: error }, 'Firebase ID token verification failed');
      throw error;
    }

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || null,
      phoneNumber: decodedToken.phone_number || null,
    };
    next();
  });

  return { authenticate };
}

module.exports = createAuthMiddleware();
module.exports.createAuthMiddleware = createAuthMiddleware;
