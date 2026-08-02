'use strict';

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/response');
const { HTTP_STATUS } = require('../constants');
const paymentService = require('../modules/payments/payment.service');
const { paymentTrace } = require('../utils/paymentTrace'); // TEMPORARY — see paymentTrace.js

const createCheckout = asyncHandler(async (req, res) => {
  const checkout = await paymentService.createCheckout(req.user.uid, req.body);
  sendSuccess(res, { checkout }, HTTP_STATUS.CREATED);
});

const retryCheckout = asyncHandler(async (req, res) => {
  const checkout = await paymentService.retryPayment(req.user.uid, req.params.orderId, req.body.storeId);
  sendSuccess(res, { checkout });
});

const getCheckoutStatus = asyncHandler(async (req, res) => {
  paymentTrace(9, 'entered', { orderId: req.params.orderId });
  const status = await paymentService.getCheckoutStatus(req.user.uid, req.params.orderId);
  paymentTrace(9, 'exited', {
    orderId: req.params.orderId,
    orderStatus: status.orderStatus,
    paymentStatus: status.paymentStatus,
    paymentId: status.paymentId,
    transactionId: status.transactionId,
  });
  sendSuccess(res, { status });
});

const cancelCheckout = asyncHandler(async (req, res) => {
  const payment = await paymentService.cancelCheckout(req.user.uid, req.params.paymentId);
  sendSuccess(res, { payment });
});

module.exports = { createCheckout, retryCheckout, getCheckoutStatus, cancelCheckout };
