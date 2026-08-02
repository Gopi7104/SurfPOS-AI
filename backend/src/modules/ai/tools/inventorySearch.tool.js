'use strict';

// Placeholder — not implemented, not registered anywhere. See tool.interface.js and
// docs/16_AI_MODULE.md "Future Tool Architecture". Will eventually let SurfAI search
// modules/inventory/inventory.service.js on the merchant's behalf.

const { notImplemented } = require('./tool.interface');

/** @type {import('./tool.interface').AiTool} */
const inventorySearchTool = {
  name: 'inventory_search',
  description: 'Search the merchant’s product catalog by name, SKU, barcode, or category.',
  parameters: {
    type: 'object',
    properties: {
      query: { type: 'string', description: 'Search text (name, SKU, or barcode).' },
    },
    required: ['query'],
  },
  execute: notImplemented('inventory_search'),
};

module.exports = inventorySearchTool;
