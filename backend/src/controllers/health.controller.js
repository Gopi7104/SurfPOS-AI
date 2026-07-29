'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const healthService = require('../services/health.service');

const getHealth = asyncHandler(async (req, res) => {
  const health = healthService.checkHealth();
  sendSuccess(res, health);
});

module.exports = { getHealth };
