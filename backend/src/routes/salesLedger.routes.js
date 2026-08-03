'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const { salesBodySchema } = require('../validators/salesLedger.validation');
const { getSales, putSales } = require('../controllers/salesLedger.controller');

const router = Router();

// Bulk-sync resource: the whole sales ledger as one JSON array — see
// modules/reports/salesLedger.repository.js header comment.
router.use(authenticate);

router.get('/', getSales);
router.post('/', validate(salesBodySchema), putSales);

module.exports = router;
