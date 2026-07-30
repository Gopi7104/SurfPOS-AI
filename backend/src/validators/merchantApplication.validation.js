'use strict';

// Request-shape validation for the merchant-application resource — see docs/07_CODING_RULES.md §
// 10. Shape confirmed against the real Surfboard Create Merchant API (docs/08_ARCHITECTURE_DECISIONS.md
// § ADR-025) — replaces the earlier guessed businessName/businessType/contactEmail/contactPhone
// shape entirely. Store is required (not merely "recommended" per Surfboard's docs) since SurfPOS
// is in-store-only — an onboarded merchant with no store can't process payments yet.

const { z } = require('zod');

const addressSchema = z.object({
  careOf: z.string().min(1).optional(),
  addressLine1: z.string().min(1),
  addressLine2: z.string().min(1).optional(),
  city: z.string().min(1),
  countryCode: z.string().length(2),
  postalCode: z.string().min(1),
});

const phoneNumberSchema = z.object({
  code: z.string().regex(/^\d{1,4}$/, 'Must be a numeric country calling code (no +)'),
  number: z.string().regex(/^\d{5,15}$/, 'Must be 5-15 digits'),
});

const submitApplicationSchema = z.object({
  country: z.string().length(2),
  organisation: z.object({
    corporateId: z.string().min(1),
    legalName: z.string().min(1).optional(),
    mccCode: z
      .string()
      .regex(/^\d{4}$/, 'Must be a 4-digit Merchant Category Code')
      .optional(),
    address: addressSchema,
    phoneNumber: phoneNumberSchema.optional(),
    email: z.string().email().optional(),
  }),
  store: z.object({
    name: z.string().min(1),
    email: z.string().email(),
    phoneNumber: phoneNumberSchema,
    address: addressSchema,
  }),
});

const applicationIdParamsSchema = z.object({
  id: z.string().min(1),
});

module.exports = { submitApplicationSchema, applicationIdParamsSchema };
