'use strict';

// JSDoc-only type definitions — see src/types/README.md. No runtime exports.
// Mirrors the envelope shape in docs/04_API_DOCUMENTATION.md § 1 and utils/response.js.

/**
 * @typedef {Object} SuccessResponse
 * @property {true} success
 * @property {*} data
 */

/**
 * @typedef {Object} ErrorResponseBody
 * @property {string} code
 * @property {string} message
 * @property {unknown[]} details
 */

/**
 * @typedef {Object} ErrorResponse
 * @property {false} success
 * @property {ErrorResponseBody} error
 */

module.exports = {};
