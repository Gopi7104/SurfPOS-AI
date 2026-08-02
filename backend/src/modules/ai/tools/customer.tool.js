'use strict';

// Placeholder — not implemented, not registered anywhere. See tool.interface.js and
// docs/16_AI_MODULE.md "Future Tool Architecture". Will eventually let SurfAI look up customer
// records/purchase history via the Customers module.

const { notImplemented } = require('./tool.interface');

/** @type {import('./tool.interface').AiTool} */
const customerTool = {
  name: 'customer_lookup',
  description: 'Look up a customer’s profile or purchase history.',
  parameters: {
    type: 'object',
    properties: {
      query: { type: 'string', description: 'Customer name, phone, or email.' },
    },
    required: ['query'],
  },
  execute: notImplemented('customer_lookup'),
};

module.exports = customerTool;
