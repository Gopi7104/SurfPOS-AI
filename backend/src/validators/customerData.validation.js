'use strict';

// Request-shape validation for the customer-data bulk-sync resource (see
// docs/07_CODING_RULES.md § 10). Deliberately loose — each entry's real shape is owned by the
// Flutter app's CustomerModel/CustomerPurchase (see modules/customers/customerData.repository.js
// header comment); this only guards against a malformed body, not every individual field.

const { z } = require('zod');

const customersBodySchema = z.object({
  customers: z.array(z.record(z.string(), z.unknown())),
});

const purchasesBodySchema = z.object({
  purchases: z.array(z.record(z.string(), z.unknown())),
});

module.exports = { customersBodySchema, purchasesBodySchema };
