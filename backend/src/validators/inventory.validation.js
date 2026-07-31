'use strict';

// Request-shape validation for the inventory (product + stock) resource — see
// docs/07_CODING_RULES.md § 10.

const { z } = require('zod');

const createProductSchema = z.object({
  name: z.string().min(2),
  description: z.string().max(2000).optional(),
  sku: z.string().min(1),
  barcode: z.string().min(1).optional(),
  category: z.string().min(1).optional(),
  unit: z.string().min(1),
  costPrice: z.number().min(0),
  sellingPrice: z.number().min(0),
  taxRate: z.number().min(0).max(100),
  discountPercentage: z.number().min(0).max(100).optional(),
  supplierId: z.string().min(1).optional(),
  imageUrl: z.string().url().optional(),
  reorderLevel: z.number().min(0).optional(),
  status: z.enum(['ACTIVE', 'INACTIVE']).optional(),
});

const updateProductSchema = createProductSchema
  .partial()
  .refine((body) => Object.keys(body).length > 0, { message: 'At least one field must be provided' });

const productIdParamsSchema = z.object({
  productId: z.string().min(1),
});

const getProductQuerySchema = z.object({
  storeId: z.string().min(1).optional(),
});

const listProductsQuerySchema = z.object({
  search: z.string().min(1).optional(),
  category: z.string().min(1).optional(),
  barcode: z.string().min(1).optional(),
  status: z.enum(['ACTIVE', 'INACTIVE']).optional(),
  includeInactive: z
    .enum(['true', 'false'])
    .optional()
    .transform((value) => value === 'true'),
  stockFilter: z.enum(['lowStock', 'inStock', 'outOfStock']).optional(),
  sortBy: z.enum(['name', 'price', 'stock', 'updatedAt', 'createdAt']).optional(),
  sortOrder: z.enum(['asc', 'desc']).optional(),
  storeId: z.string().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
  cursor: z.string().min(1).optional(),
});

const adjustStockSchema = z.object({
  storeId: z.string().min(1),
  quantityDelta: z
    .number()
    .int()
    .refine((value) => value !== 0, { message: 'quantityDelta must not be zero' }),
  reason: z.string().min(1).optional(),
});

module.exports = {
  createProductSchema,
  updateProductSchema,
  productIdParamsSchema,
  getProductQuerySchema,
  listProductsQuerySchema,
  adjustStockSchema,
};
