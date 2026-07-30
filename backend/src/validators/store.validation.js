'use strict';

// Request-shape validation for the store resource — see docs/07_CODING_RULES.md § 10.

const { z } = require('zod');

const addressSchema = z.object({
  line1: z.string().min(1),
  city: z.string().min(1),
  country: z.string().length(2),
});

const createStoreSchema = z.object({
  name: z.string().min(2),
  address: addressSchema,
});

const updateStoreSchema = z
  .object({
    name: z.string().min(2).optional(),
    address: addressSchema.optional(),
  })
  .refine((body) => Object.keys(body).length > 0, {
    message: 'At least one field must be provided',
  });

const storeIdParamsSchema = z.object({
  storeId: z.string().min(1),
});

module.exports = { createStoreSchema, updateStoreSchema, storeIdParamsSchema };
