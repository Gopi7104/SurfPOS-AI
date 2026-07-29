'use strict';

// Centralized error handler — the only place a thrown/forwarded error becomes an HTTP response.
// Must be registered last, after every route — see docs/07_CODING_RULES.md § 7.

const { AppError } = require('../utils/errors');
const { sendError } = require('../utils/response');
const config = require('../config');
const { logger } = require('../utils/logger');
const { HTTP_STATUS, ERROR_CODES, MESSAGES } = require('../constants');

// eslint-disable-next-line no-unused-vars -- Express only treats a 4-arg function as error middleware
function errorMiddleware(err, req, res, next) {
  const log = req.log || logger;

  if (err instanceof AppError) {
    if (err.statusCode >= HTTP_STATUS.INTERNAL_SERVER_ERROR) {
      log.error({ err }, err.message);
    } else {
      log.warn({ code: err.code, message: err.message }, 'Request failed validation/authorization');
    }

    sendError(res, {
      code: err.code,
      message: err.message,
      details: err.details,
      statusCode: err.statusCode,
    });
    return;
  }

  log.error({ err }, 'Unhandled error');
  sendError(res, {
    code: ERROR_CODES.INTERNAL_ERROR,
    message: config.isProduction ? MESSAGES.INTERNAL_ERROR_PUBLIC : err.message,
    statusCode: HTTP_STATUS.INTERNAL_SERVER_ERROR,
  });
}

module.exports = errorMiddleware;
