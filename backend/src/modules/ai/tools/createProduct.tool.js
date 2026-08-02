'use strict';

// Placeholder — not implemented, not registered anywhere. See tool.interface.js and
// docs/16_AI_MODULE.md "Future Tool Architecture". Will eventually let SurfAI create a product via
// modules/inventory/inventory.service.js on the merchant's behalf, after explicit confirmation.

const { notImplemented } = require('./tool.interface');

/** @type {import('./tool.interface').AiTool} */
const createProductTool = {
  name: 'create_product',
  description: 'Create a new product in the merchant’s inventory.',
  parameters: {
    type: 'object',
    properties: {
      name: { type: 'string' },
      sku: { type: 'string' },
      sellingPrice: { type: 'number' },
    },
    required: ['name', 'sku', 'sellingPrice'],
  },
  execute: notImplemented('create_product'),
};

module.exports = createProductTool;
