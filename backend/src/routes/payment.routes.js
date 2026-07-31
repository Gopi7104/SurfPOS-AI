'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  createCheckoutSchema,
  retryCheckoutSchema,
  orderIdParamsSchema,
  paymentIdParamsSchema,
} = require('../validators/payment.validation');
const {
  createCheckout,
  retryCheckout,
  getCheckoutStatus,
  cancelCheckout,
} = require('../controllers/payment.controller');

const router = Router();

// All payment endpoints require an authenticated SurfPOS user with a resolved merchant reference —
// see docs/04_API_DOCUMENTATION.md § 8.
router.use(authenticate);

router.post('/checkout', validate(createCheckoutSchema), createCheckout);
router.get('/checkout/:orderId/status', validate(orderIdParamsSchema, 'params'), getCheckoutStatus);
router.post(
  '/checkout/:orderId/retry',
  validate(orderIdParamsSchema, 'params'),
  validate(retryCheckoutSchema),
  retryCheckout,
);
router.delete('/:paymentId', validate(paymentIdParamsSchema, 'params'), cancelCheckout);

module.exports = router;
