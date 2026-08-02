'use strict';

// Lightweight, deterministic intent detection for SurfAI chat (Phase AI-2 tool calling, extended
// in Phase AI-3 with navigation). Deliberately NOT LLM-based: `ai.service.js` checks the caller's
// latest message against this fixed, ordered list of keyword/phrase patterns *before* ever calling
// OpenRouter. The first pattern that matches wins — OpenRouter is only consulted when nothing here
// matches, so a question/command the backend can already answer never costs a token.
//
// Order matters: patterns are listed most-specific-first so a narrower phrase is never shadowed
// by a broader one that also happens to appear inside it — e.g. "revenue today" (dashboard) is
// checked before the bare "revenue" (reports), and "merchant name" (settings) before the bare
// "merchant" catch-all.
//
// Phase AI-3 intent priority: `tool: 'navigation'` entries are checked FIRST, ahead of every
// tool category — see ai.service.js, which never sends a navigation match to OpenRouter and never
// runs it as a backend tool either (navigation can only execute client-side, in Flutter). The
// generic `navigation.search` catch-all is instead placed LAST (after every other pattern,
// including the more specific `customer`/`billing` search patterns below), so "search Coca Cola"
// only opens Inventory once nothing more specific already claimed the message.

const PATTERNS = [
  // Navigation — checked before any tool category (see this file's header comment). Execution is
  // entirely client-side (tab switches, route pushes, provider state) — see ai.service.js and
  // frontend/lib/features/ai/controllers/ai_chat_controller.dart.
  { tool: 'navigation', function: 'openAddProduct', test: /\bopen\s+add\s*product\b/i },
  { tool: 'navigation', function: 'openBilling', test: /\bopen\s+billing\b/i },
  { tool: 'navigation', function: 'openInventory', test: /\bopen\s+inventory\b/i },
  { tool: 'navigation', function: 'openReports', test: /\bopen\s+reports?\b/i },
  { tool: 'navigation', function: 'openCustomers', test: /\bopen\s+customers?\b/i },
  { tool: 'navigation', function: 'openSettings', test: /\bopen\s+settings\b/i },
  { tool: 'navigation', function: 'openDashboard', test: /\bopen\s+dashboard\b/i },
  {
    tool: 'navigation',
    function: 'startNewSale',
    test: /\b(?:start\s+(?:a\s+)?new\s+sale|new\s+sale)\b/i,
  },
  {
    tool: 'navigation',
    function: 'generateDemoData',
    test: /\bgenerate\s+demo\s*(?:data|business)\b/i,
  },

  // Inventory — most specific first (barcode/category/details before the generic search catch-all).
  { tool: 'inventory', function: 'lowStock', test: /\blow[\s-]?stock\b/i },
  { tool: 'inventory', function: 'outOfStock', test: /\bout[\s-]?of[\s-]?stock\b/i },
  { tool: 'inventory', function: 'count', test: /\b(?:product|inventory)\s*count\b|how many products\b/i },
  {
    tool: 'inventory',
    function: 'inventoryValue',
    test: /\b(?:inventory|stock)\s*value\b|total value of (?:inventory|stock)\b/i,
  },
  {
    tool: 'inventory',
    function: 'barcodeSearch',
    test: /\bbarcode\b\s*(.*)$/i,
    extract: (m) => ({ barcode: m[1]?.trim() || undefined }),
  },
  // "top category" (reports) must be checked before the generic inventory category pattern below,
  // since it also contains the bare word "category".
  { tool: 'reports', function: 'topCategory', test: /\btop\s*category\b/i },
  {
    tool: 'inventory',
    function: 'categorySearch',
    test: /\bcategory\b\s*(.*)$/i,
    extract: (m) => ({ category: m[1]?.trim() || undefined }),
  },
  {
    tool: 'inventory',
    function: 'details',
    test: /\b(?:details? (?:of|for|about)|tell me about)\s+(.+)$/i,
    extract: (m) => ({ query: m[1]?.trim() || undefined }),
  },
  {
    tool: 'inventory',
    function: 'search',
    test: /\b(?:search|show|find|list)\b.*\b(?:products?|inventory)\b(?:\s+(?:for|named|called)\s*(.*))?$/i,
    extract: (m) => ({ query: m[1]?.trim() || undefined }),
  },

  // Reports/Dashboard — "today/customers today" (dashboard) before the bare "revenue" (reports).
  // "revenue summary" must be checked before the bare "revenue" pattern below, same reason as
  // "top category" above.
  { tool: 'reports', function: 'revenueSummary', test: /\brevenue\s*summary\b/i },
  { tool: 'reports', function: 'salesTrend', test: /\bsales\s*trend\b/i },
  { tool: 'reports', function: 'paymentBreakdown', test: /\bpayment\s*breakdown\b/i },
  { tool: 'reports', function: 'inventoryHealth', test: /\binventory\s*health\b/i },
  { tool: 'reports', function: 'kpiMetrics', test: /\bkpis?\b|\bkey\s*metrics?\b/i },
  { tool: 'reports', function: 'today', test: /\btoday(?:'s)?\s*sales\b/i },
  { tool: 'reports', function: 'weekly', test: /\bweekly\s*sales\b/i },
  { tool: 'reports', function: 'monthly', test: /\bmonthly\s*sales\b/i },
  { tool: 'reports', function: 'bestSeller', test: /\bbest[\s-]?sell(?:er|ing)\b/i },
  { tool: 'reports', function: 'averageOrder', test: /\baverage\s*order\b/i },
  { tool: 'dashboard', function: 'revenueToday', test: /\brevenue\s*today\b/i },
  { tool: 'dashboard', function: 'customersToday', test: /\bcustomers?\s*today\b/i },
  { tool: 'dashboard', function: 'businessInsights', test: /\bbusiness\s*insights?\b/i },
  { tool: 'dashboard', function: 'growth', test: /\bgrowth\b/i },
  { tool: 'dashboard', function: 'quickStatistics', test: /\bquick\s*stat(?:s|istics)?\b/i },
  { tool: 'reports', function: 'ordersToday', test: /\borders?\s*today\b/i },
  { tool: 'reports', function: 'revenue', test: /\brevenue\b/i },

  // Customer
  { tool: 'customer', function: 'count', test: /\bcustomer\s*count\b/i },
  { tool: 'customer', function: 'vipCustomers', test: /\bvip\s*customers?\b/i },
  { tool: 'customer', function: 'topCustomer', test: /\btop\s*customer\b/i },
  { tool: 'customer', function: 'recentCustomer', test: /\brecent\s*customer\b/i },
  { tool: 'customer', function: 'customerStatistics', test: /\bcustomer\s*stat(?:s|istics)?\b/i },
  // "customer loyalty <name>"/"customer points <name>" before the bare, name-less form below.
  {
    tool: 'customer',
    function: 'loyalty',
    test: /\bcustomer\s*(?:loyalty|points)\s+(?:for\s+)?(.+)$/i,
    extract: (m) => ({ query: m[1]?.trim() || undefined }),
  },
  { tool: 'customer', function: 'loyalty', test: /\bcustomer\s*(?:loyalty|points)\b/i },
  {
    tool: 'customer',
    function: 'search',
    test: /\b(?:search\s+(?:for\s+)?customer|show\s+customer)\b\s*(.*)$/i,
    extract: (m) => ({ query: m[1]?.trim() || undefined }),
  },

  // Billing — real, client-side cart state (see ClientAiToolExecutor.dart).
  { tool: 'billing', function: 'currentCart', test: /\bcurrent\s*cart\b/i },
  { tool: 'billing', function: 'currentProducts', test: /\bcurrent\s*products?\b/i },
  { tool: 'billing', function: 'grandTotal', test: /\bgrand\s*total\b/i },
  { tool: 'billing', function: 'cartTotal', test: /\bcart\s*total\b/i },
  { tool: 'billing', function: 'itemCount', test: /\bitem\s*count\b/i },
  { tool: 'billing', function: 'discount', test: /\bdiscount\b/i },
  { tool: 'billing', function: 'tax', test: /\btax\b/i },
  {
    tool: 'billing',
    function: 'searchItem',
    test: /\bsearch\s+(?:for\s+)?item\b\s*(.*)$/i,
    extract: (m) => ({ query: m[1]?.trim() || undefined }),
  },

  // Settings — "merchant name"/"store info" before the bare "merchant" catch-all.
  { tool: 'settings', function: 'appVersion', test: /\bapp\s*version\b/i },
  { tool: 'settings', function: 'theme', test: /\btheme\b/i },
  { tool: 'settings', function: 'printerStatus', test: /\bprinter\s*status\b/i },
  { tool: 'settings', function: 'merchantName', test: /\bmerchant\s*name\b/i },
  { tool: 'settings', function: 'store', test: /\bmerchant\b|\bstore\s*(?:info|information|details)\b/i },

  // Generic "search <product name>" navigation catch-all — deliberately LAST: every more specific
  // search pattern above (inventory.search, customer.search, billing.searchItem) already requires
  // its own domain keyword ("product(s)"/"inventory", "customer", "item") and is checked first, so
  // this only fires for a bare product name like "search Coca Cola" that matched nothing else.
  {
    tool: 'navigation',
    function: 'searchInventory',
    test: /^search\s+(.+)$/i,
    extract: (m) => ({ query: m[1]?.trim() || undefined }),
  },
];

/**
 * @param {string} message the caller's latest user message (not the whole conversation)
 * @returns {{ tool: string, function: string, params: object }|null} `null` means "no backend
 *   tool can answer this — fall through to OpenRouter."
 */
function detectIntent(message) {
  if (typeof message !== 'string') return null;
  const trimmed = message.trim();
  if (!trimmed) return null;

  for (const pattern of PATTERNS) {
    const match = trimmed.match(pattern.test);
    if (match) {
      return {
        tool: pattern.tool,
        function: pattern.function,
        params: pattern.extract ? pattern.extract(match) : {},
      };
    }
  }
  return null;
}

module.exports = { detectIntent };
