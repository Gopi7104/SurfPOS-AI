'use strict';

// Placeholder — not implemented, not registered anywhere. See tool.interface.js and
// docs/16_AI_MODULE.md "Future Tool Architecture". Will eventually let SurfAI answer billing
// questions (recent sales, receipt lookup) via modules/billing/billing.service.js.

const { notImplemented } = require('./tool.interface');

/** @type {import('./tool.interface').AiTool} */
const billingTool = {
  name: 'billing_lookup',
  description: 'Look up recent sales, receipts, or billing totals for the merchant.',
  parameters: {
    type: 'object',
    properties: {
      period: { type: 'string', description: 'e.g. "today", "this_week", "this_month".' },
    },
    required: ['period'],
  },
  execute: notImplemented('billing_lookup'),
};

module.exports = billingTool;
