'use strict';

// Request-shape validation for the merchant-application resource — see docs/07_CODING_RULES.md § 10.

const { z } = require('zod');
const { REGEX } = require('../constants');

const submitApplicationSchema = z.object({
  businessName: z.string().min(2),
  businessType: z.string().min(1),
  contactEmail: z.string().email(),
  contactPhone: z.string().regex(REGEX.E164_PHONE, 'Must be E.164 format'),
  address: z.object({
    line1: z.string().min(1),
    city: z.string().min(1),
    country: z.string().length(2),
  }),
});

const applicationIdParamsSchema = z.object({
  id: z.string().min(1),
});

module.exports = { submitApplicationSchema, applicationIdParamsSchema };
