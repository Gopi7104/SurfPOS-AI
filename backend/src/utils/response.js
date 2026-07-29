'use strict';

// Standard response envelope for every endpoint — see docs/04_API_DOCUMENTATION.md § 1.

const { HTTP_STATUS, ERROR_CODES } = require('../constants');

/**
 * @param {import('express').Response} res
 * @param {*} data
 * @param {number} [statusCode]
 */
function sendSuccess(res, data, statusCode = HTTP_STATUS.OK) {
  return res.status(statusCode).json({ success: true, data });
}

/**
 * @param {import('express').Response} res
 * @param {{ code: string, message: string, details?: unknown[], statusCode?: number }} error
 */
function sendError(
  res,
  {
    code = ERROR_CODES.INTERNAL_ERROR,
    message,
    details = [],
    statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR,
  },
) {
  return res.status(statusCode).json({ success: false, error: { code, message, details } });
}

module.exports = { sendSuccess, sendError };
