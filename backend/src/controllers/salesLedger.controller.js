'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const salesLedgerService = require('../modules/reports/salesLedger.service');

const getSales = asyncHandler(async (req, res) => {
  const records = await salesLedgerService.getSales(req.user.uid);
  sendSuccess(res, { records });
});

const putSales = asyncHandler(async (req, res) => {
  const records = await salesLedgerService.setSales(req.user.uid, req.body.records);
  sendSuccess(res, { records });
});

module.exports = { getSales, putSales };
