'use strict';

// Default human-readable messages paired with constants/errorCodes.js — kept separate from the
// codes themselves so wording can change without touching anything that switches on a code.

module.exports = Object.freeze({
  VALIDATION_FAILED: 'Request validation failed',
  MISSING_TOKEN: 'Missing bearer token',
  INVALID_TOKEN: 'Invalid or expired authentication token',
  FORBIDDEN: 'You do not have permission to access this resource',
  NOT_FOUND: 'Resource not found',
  CONFLICT: 'Resource conflict',
  RATE_LIMITED: 'Too many requests — please try again later',
  INTERNAL_ERROR_PUBLIC: 'Something went wrong',
  SURFBOARD_ERROR: 'Surfboard request failed',
  SURFBOARD_TIMEOUT: 'Surfboard request timed out',
  EMAIL_ALREADY_IN_USE: 'An account with this email already exists',
  USER_PROFILE_NOT_FOUND: 'User profile not found',
  MERCHANT_APPLICATION_ALREADY_EXISTS: 'A merchant application already exists for this account',
  MERCHANT_APPLICATION_NOT_FOUND: 'Merchant application not found',
  MERCHANT_REFERENCE_NOT_FOUND:
    'No merchant reference found for this account — submit a merchant application first, or wait for it to be approved',
  routeNotFound: (method, path) => `Route not found: ${method} ${path}`,
});
