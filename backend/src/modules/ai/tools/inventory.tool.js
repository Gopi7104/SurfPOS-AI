'use strict';

// Real, read-only SurfAI tool functions over modules/inventory/inventory.service.js — routed here
// by intent/intentDetector.js. Only ever calls inventoryService, never inventory's own Repository
// directly, per the cross-module rule (docs/21_BACKEND_GUIDELINES.md § 8).
//
// Every function returns `{ available: boolean, message: string }` — `message` is a plain
// natural-language string the chat UI renders directly in a "tool result" bubble (see
// ai.service.js). `available: true` here always, since this category has real backing data;
// billing/reports/dashboard/customer tools use `available: false` for their "not built yet" stubs.

const defaultInventoryService = require('../../inventory/inventory.service');

const SEARCH_RESULT_LIMIT = 8;
const FULL_CATALOG_PAGE_SIZE = 100;
const FULL_CATALOG_MAX_PAGES = 20; // bounds count()/inventoryValue() to 2,000 products, plenty for a small merchant

function formatProductLine(product) {
  const price = typeof product.sellingPrice === 'number' ? `$${product.sellingPrice.toFixed(2)}` : '—';
  return `- ${product.name} (${product.sku ?? 'no SKU'}) — ${price}, ${product.stockQuantity} in stock`;
}

function createInventoryTool({ inventoryService = defaultInventoryService } = {}) {
  /** Walks every page of `listProducts` — needed for count()/inventoryValue(), which must see the whole catalog, not one page. */
  async function collectAllProducts(uid, query = {}) {
    const items = [];
    let cursor;
    for (let page = 0; page < FULL_CATALOG_MAX_PAGES; page += 1) {
      const result = await inventoryService.listProducts(uid, {
        ...query,
        limit: FULL_CATALOG_PAGE_SIZE,
        cursor,
      });
      items.push(...result.items);
      if (!result.nextCursor) break;
      cursor = result.nextCursor;
    }
    return items;
  }

  async function search(uid, { query } = {}) {
    const { items } = await inventoryService.listProducts(uid, {
      search: query || undefined,
      limit: SEARCH_RESULT_LIMIT,
    });
    if (!items.length) {
      return {
        available: true,
        message: query
          ? `No products found matching "${query}".`
          : 'No products found in your inventory yet.',
      };
    }
    const heading = query
      ? `Found ${items.length} product(s) matching "${query}":`
      : `Here are your first ${items.length} product(s):`;
    return { available: true, message: [heading, ...items.map(formatProductLine)].join('\n') };
  }

  async function details(uid, { query } = {}) {
    if (!query) {
      return { available: true, message: 'Which product would you like details for?' };
    }
    const { items } = await inventoryService.listProducts(uid, { search: query, limit: 1 });
    const product = items[0];
    if (!product) {
      return { available: true, message: `I couldn't find a product matching "${query}".` };
    }
    const lines = [
      `**${product.name}**`,
      `SKU: ${product.sku ?? '—'}`,
      `Category: ${product.category ?? '—'}`,
      `Price: $${(product.sellingPrice ?? 0).toFixed(2)}`,
      `In stock: ${product.stockQuantity}`,
    ];
    return { available: true, message: lines.join('\n') };
  }

  async function lowStock(uid) {
    const { items } = await inventoryService.listProducts(uid, {
      stockFilter: 'lowStock',
      limit: SEARCH_RESULT_LIMIT,
    });
    if (!items.length) {
      return { available: true, message: 'Nothing is running low right now.' };
    }
    return {
      available: true,
      message: [`${items.length} product(s) running low:`, ...items.map(formatProductLine)].join('\n'),
    };
  }

  async function outOfStock(uid) {
    const { items } = await inventoryService.listProducts(uid, {
      stockFilter: 'outOfStock',
      limit: SEARCH_RESULT_LIMIT,
    });
    if (!items.length) {
      return { available: true, message: 'Nothing is out of stock right now.' };
    }
    return {
      available: true,
      message: [`${items.length} product(s) out of stock:`, ...items.map(formatProductLine)].join('\n'),
    };
  }

  async function count(uid) {
    const items = await collectAllProducts(uid);
    return { available: true, message: `You have ${items.length} product(s) in your inventory.` };
  }

  async function barcodeSearch(uid, { barcode } = {}) {
    if (!barcode) {
      return { available: true, message: 'What barcode should I look up?' };
    }
    const { items } = await inventoryService.listProducts(uid, { barcode, limit: 1 });
    const product = items[0];
    if (!product) {
      return { available: true, message: `No product found with barcode "${barcode}".` };
    }
    return { available: true, message: formatProductLine(product) };
  }

  async function categorySearch(uid, { category } = {}) {
    if (!category) {
      return { available: true, message: 'Which category should I search?' };
    }
    const { items } = await inventoryService.listProducts(uid, { category, limit: SEARCH_RESULT_LIMIT });
    if (!items.length) {
      return { available: true, message: `No products found in category "${category}".` };
    }
    return {
      available: true,
      message: [`${items.length} product(s) in "${category}":`, ...items.map(formatProductLine)].join('\n'),
    };
  }

  async function inventoryValue(uid) {
    const items = await collectAllProducts(uid);
    const total = items.reduce(
      (sum, product) => sum + (product.sellingPrice ?? 0) * (product.stockQuantity ?? 0),
      0,
    );
    return {
      available: true,
      message: `Your current inventory is worth $${total.toFixed(2)} at selling price, across ${items.length} product(s).`,
    };
  }

  return { search, details, lowStock, outOfStock, count, barcodeSearch, categorySearch, inventoryValue };
}

module.exports = createInventoryTool();
module.exports.createInventoryTool = createInventoryTool;
