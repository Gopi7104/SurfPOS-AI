'use strict';

// Wraps an async controller so a rejected promise reaches error.middleware.js via next(),
// instead of becoming an unhandled rejection — see docs/07_CODING_RULES.md § 15.

/**
 * @param {(req: import('express').Request, res: import('express').Response, next: import('express').NextFunction) => Promise<*>} fn
 */
function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

module.exports = asyncHandler;
