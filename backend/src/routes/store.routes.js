'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  createStoreSchema,
  updateStoreSchema,
  storeIdParamsSchema,
} = require('../validators/store.validation');
const { createStore, getStore, updateStore, listStores } = require('../controllers/store.controller');

const router = Router();

// All store endpoints require an authenticated SurfPOS user with a resolved merchant reference —
// see docs/04_API_DOCUMENTATION.md § 3.
router.use(authenticate);

router.post('/', validate(createStoreSchema), createStore);
router.get('/', listStores);
router.get('/:storeId', validate(storeIdParamsSchema, 'params'), getStore);
router.patch('/:storeId', validate(storeIdParamsSchema, 'params'), validate(updateStoreSchema), updateStore);

module.exports = router;
