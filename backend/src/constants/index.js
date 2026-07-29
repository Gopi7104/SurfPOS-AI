'use strict';

const HTTP_STATUS = require('./httpStatus');
const ERROR_CODES = require('./errorCodes');
const MESSAGES = require('./messages');
const ROLES = require('./roles');
const PERMISSIONS = require('./permissions');
const API_ROUTES = require('./apiRoutes');
const API_VERSION = require('./apiVersion');
const REGEX = require('./regex');
const ENV_KEYS = require('./environmentKeys');

module.exports = {
  HTTP_STATUS,
  ERROR_CODES,
  MESSAGES,
  ROLES,
  PERMISSIONS,
  API_ROUTES,
  API_VERSION,
  REGEX,
  ENV_KEYS,
};
