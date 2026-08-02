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
  STORE_NOT_FOUND: 'Store not found',
  PRODUCT_NOT_FOUND: 'Product not found',
  DUPLICATE_SKU: 'A product with this SKU already exists',
  INSUFFICIENT_STOCK: 'Insufficient stock for this adjustment',
  NO_STORE_AVAILABLE: 'No store is set up for this merchant yet — create a store before taking payments',
  ORDER_NOT_FOUND: 'Order not found',
  ORDER_RETRY_CONTEXT_NOT_FOUND:
    'Original order details are no longer available for retry — start a new checkout',
  INVALID_WEBHOOK_SIGNATURE: 'Invalid webhook signature',
  MISSING_WEBHOOK_SIGNATURE: 'Missing x-webhook-signature header',
  routeNotFound: (method, path) => `Route not found: ${method} ${path}`,
});
