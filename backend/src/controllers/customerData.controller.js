'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const customerDataService = require('../modules/customers/customerData.service');

const getCustomers = asyncHandler(async (req, res) => {
  const customers = await customerDataService.getCustomers(req.user.uid);
  sendSuccess(res, { customers });
});

const putCustomers = asyncHandler(async (req, res) => {
  const customers = await customerDataService.setCustomers(req.user.uid, req.body.customers);
  sendSuccess(res, { customers });
});

const getPurchases = asyncHandler(async (req, res) => {
  const purchases = await customerDataService.getPurchases(req.user.uid);
  sendSuccess(res, { purchases });
});

const putPurchases = asyncHandler(async (req, res) => {
  const purchases = await customerDataService.setPurchases(req.user.uid, req.body.purchases);
  sendSuccess(res, { purchases });
});

module.exports = { getCustomers, putCustomers, getPurchases, putPurchases };
