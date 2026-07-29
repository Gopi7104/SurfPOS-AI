'use strict';

// Request-shape validation for the merchant-profile resource — see docs/07_CODING_RULES.md § 10.

const { z } = require('zod');
const { REGEX } = require('../constants');

const updateMerchantSchema = z
  .object({
    businessName: z.string().min(2).optional(),
    businessType: z.string().min(1).optional(),
    contactEmail: z.string().email().optional(),
    contactPhone: z.string().regex(REGEX.E164_PHONE, 'Must be E.164 format').optional(),
    address: z
      .object({
        line1: z.string().min(1),
        city: z.string().min(1),
        country: z.string().length(2),
      })
      .optional(),
  })
  .refine((body) => Object.keys(body).length > 0, {
    message: 'At least one field must be provided',
  });

module.exports = { updateMerchantSchema };
