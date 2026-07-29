'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const { updateMerchantSchema } = require('../validators/merchant.validation');
const { getMerchant, updateMerchant, getMerchantStatus } = require('../controllers/merchant.controller');

const router = Router();

// All merchant-profile endpoints require an authenticated SurfPOS user with a resolved merchant
// reference — see docs/04_API_DOCUMENTATION.md § 3.
router.use(authenticate);

router.get('/status', getMerchantStatus);
router.get('/', getMerchant);
router.patch('/', validate(updateMerchantSchema), updateMerchant);

module.exports = router;
