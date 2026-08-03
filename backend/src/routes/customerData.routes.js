'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const { customersBodySchema, purchasesBodySchema } = require('../validators/customerData.validation');
const {
  getCustomers,
  putCustomers,
  getPurchases,
  putPurchases,
} = require('../controllers/customerData.controller');

const router = Router();

// Bulk-sync resource: the whole customer list / whole purchase-history list as one JSON array —
// see modules/customers/customerData.repository.js header comment. All endpoints require an
// authenticated SurfPOS user with a resolved merchant reference, same as /inventory.
router.use(authenticate);

router.get('/', getCustomers);
router.post('/', validate(customersBodySchema), putCustomers);
router.get('/purchases', getPurchases);
router.post('/purchases', validate(purchasesBodySchema), putPurchases);

module.exports = router;
