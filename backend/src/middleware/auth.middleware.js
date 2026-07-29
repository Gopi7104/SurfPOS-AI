'use strict';

// Verifies the Firebase ID token on every protected route — see docs/02_ARCHITECTURE.md § 11.
// A valid token proves identity only; each controller still re-checks the authenticated user's
// merchantId/storeId/role ownership of the resource being accessed (docs/07_CODING_RULES.md § 11).

const { getAuth } = require('../firebase/admin');
const { UnauthenticatedError } = require('../utils/errors');
const asyncHandler = require('../utils/asyncHandler');
const { MESSAGES } = require('../constants');

const BEARER_PREFIX = 'Bearer ';

function extractToken(req) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith(BEARER_PREFIX)) {
    return null;
  }
  return header.slice(BEARER_PREFIX.length).trim();
}

const authenticate = asyncHandler(async (req, res, next) => {
  const token = extractToken(req);
  if (!token) {
    throw new UnauthenticatedError(MESSAGES.MISSING_TOKEN);
  }

  try {
    const decodedToken = await getAuth().verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || null,
      phoneNumber: decodedToken.phone_number || null,
    };
  } catch (error) {
    req.log?.warn({ err: error }, 'Firebase ID token verification failed');
    throw new UnauthenticatedError(MESSAGES.INVALID_TOKEN);
  }

  next();
});

module.exports = { authenticate };
