'use strict';

// Typed error hierarchy mapping to the standard error codes in docs/04_API_DOCUMENTATION.md § 1.
// error.middleware.js is the only place these get turned into an HTTP response — see
// docs/07_CODING_RULES.md § 7 (thrown as typed errors, never generic Error/magic strings).

const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../constants');

class AppError extends Error {
  constructor(
    message,
    { code = ERROR_CODES.INTERNAL_ERROR, statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR, details = [] } = {},
  ) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message = MESSAGES.VALIDATION_FAILED, details = []) {
    super(message, { code: ERROR_CODES.VALIDATION_ERROR, statusCode: HTTP_STATUS.BAD_REQUEST, details });
  }
}

class UnauthenticatedError extends AppError {
  constructor(message = MESSAGES.INVALID_TOKEN) {
    super(message, { code: ERROR_CODES.UNAUTHENTICATED, statusCode: HTTP_STATUS.UNAUTHORIZED });
  }
}

class ForbiddenError extends AppError {
  constructor(message = MESSAGES.FORBIDDEN) {
    super(message, { code: ERROR_CODES.FORBIDDEN, statusCode: HTTP_STATUS.FORBIDDEN });
  }
}

class NotFoundError extends AppError {
  constructor(message = MESSAGES.NOT_FOUND) {
    super(message, { code: ERROR_CODES.NOT_FOUND, statusCode: HTTP_STATUS.NOT_FOUND });
  }
}

class ConflictError extends AppError {
  constructor(message = MESSAGES.CONFLICT) {
    super(message, { code: ERROR_CODES.CONFLICT, statusCode: HTTP_STATUS.CONFLICT });
  }
}

class RateLimitedError extends AppError {
  constructor(message = MESSAGES.RATE_LIMITED) {
    super(message, { code: ERROR_CODES.RATE_LIMITED, statusCode: HTTP_STATUS.TOO_MANY_REQUESTS });
  }
}

class InsufficientStockError extends AppError {
  constructor(message = MESSAGES.INSUFFICIENT_STOCK) {
    super(message, { code: ERROR_CODES.INSUFFICIENT_STOCK, statusCode: HTTP_STATUS.UNPROCESSABLE_ENTITY });
  }
}

module.exports = {
  AppError,
  ValidationError,
  UnauthenticatedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  RateLimitedError,
  InsufficientStockError,
};
