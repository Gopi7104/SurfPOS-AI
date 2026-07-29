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
  routeNotFound: (method, path) => `Route not found: ${method} ${path}`,
});
