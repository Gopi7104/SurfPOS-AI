'use strict';

const { Router } = require('express');
const validate = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  createProductSchema,
  updateProductSchema,
  productIdParamsSchema,
  listProductsQuerySchema,
  adjustStockSchema,
} = require('../validators/inventory.validation');
const {
  createProduct,
  getProduct,
  updateProduct,
  deleteProduct,
  listProducts,
  adjustStock,
} = require('../controllers/inventory.controller');

const router = Router();

// All inventory endpoints require an authenticated SurfPOS user with a resolved merchant
// reference — see docs/04_API_DOCUMENTATION.md § 5-6. Firebase-owned only; never calls Surfboard.
router.use(authenticate);

router.post('/products', validate(createProductSchema), createProduct);
router.get('/products', validate(listProductsQuerySchema, 'query'), listProducts);
router.get('/products/:productId', validate(productIdParamsSchema, 'params'), getProduct);
router.patch(
  '/products/:productId',
  validate(productIdParamsSchema, 'params'),
  validate(updateProductSchema),
  updateProduct,
);
router.delete('/products/:productId', validate(productIdParamsSchema, 'params'), deleteProduct);
router.patch(
  '/products/:productId/stock',
  validate(productIdParamsSchema, 'params'),
  validate(adjustStockSchema),
  adjustStock,
);

module.exports = router;
