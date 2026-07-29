'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const merchantService = require('../modules/merchant/merchant.service');

const getMerchant = asyncHandler(async (req, res) => {
  const merchant = await merchantService.getMerchantDetails(req.user.uid);
  sendSuccess(res, { merchant });
});

const updateMerchant = asyncHandler(async (req, res) => {
  const merchant = await merchantService.updateMerchantDetails(req.user.uid, req.body);
  sendSuccess(res, { merchant });
});

const getMerchantStatus = asyncHandler(async (req, res) => {
  const status = await merchantService.getMerchantStatus(req.user.uid);
  sendSuccess(res, status);
});

module.exports = { getMerchant, updateMerchant, getMerchantStatus };
