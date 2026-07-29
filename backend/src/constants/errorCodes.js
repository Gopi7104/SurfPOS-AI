'use strict';

// Standard error codes returned in the error envelope — see docs/04_API_DOCUMENTATION.md § 1.
// INSUFFICIENT_STOCK/PAYMENT_FAILED/AI_PROCESSING_ERROR are documented here even though no module
// throws them yet, so every business module added later reuses the same code instead of inventing one.

module.exports = Object.freeze({
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  UNAUTHENTICATED: 'UNAUTHENTICATED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  INSUFFICIENT_STOCK: 'INSUFFICIENT_STOCK',
  PAYMENT_FAILED: 'PAYMENT_FAILED',
  SURFBOARD_ERROR: 'SURFBOARD_ERROR',
  AI_PROCESSING_ERROR: 'AI_PROCESSING_ERROR',
  RATE_LIMITED: 'RATE_LIMITED',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
});
