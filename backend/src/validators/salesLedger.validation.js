'use strict';

// Request-shape validation for the sales-ledger bulk-sync resource — see
// validators/customerData.validation.js's header comment for why this stays loose.

const { z } = require('zod');

const salesBodySchema = z.object({
  records: z.array(z.record(z.string(), z.unknown())),
});

module.exports = { salesBodySchema };
