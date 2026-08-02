'use strict';

// Placeholder — not implemented, not registered anywhere. See tool.interface.js and
// docs/16_AI_MODULE.md "Future Tool Architecture". Will eventually let SurfAI answer reporting
// questions (revenue, top products, trends) via the Reports module.

const { notImplemented } = require('./tool.interface');

/** @type {import('./tool.interface').AiTool} */
const reportTool = {
  name: 'report_query',
  description: 'Answer sales/revenue reporting questions for a given period.',
  parameters: {
    type: 'object',
    properties: {
      period: { type: 'string', description: 'e.g. "today", "this_week", "this_month".' },
      metric: { type: 'string', description: 'e.g. "revenue", "top_products".' },
    },
    required: ['period', 'metric'],
  },
  execute: notImplemented('report_query'),
};

module.exports = reportTool;
