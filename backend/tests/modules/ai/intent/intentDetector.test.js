import { describe, it, expect } from 'vitest';
import { detectIntent } from '../../../../src/modules/ai/intent/intentDetector.js';

describe('intentDetector', () => {
  it('returns null for an empty/blank/non-string message', () => {
    expect(detectIntent('')).toBeNull();
    expect(detectIntent('   ')).toBeNull();
    expect(detectIntent(null)).toBeNull();
    expect(detectIntent(undefined)).toBeNull();
  });

  it('returns null for a question no backend tool can answer (falls through to OpenRouter)', () => {
    expect(detectIntent('How can I increase my sales?')).toBeNull();
    expect(detectIntent('Explain GST to me')).toBeNull();
    expect(detectIntent('Give me some marketing ideas')).toBeNull();
  });

  // The spec's own worked examples — see the Phase AI-2 request.
  it.each([
    ['show products', { tool: 'inventory', function: 'search', params: { query: undefined } }],
    ['low stock', { tool: 'inventory', function: 'lowStock', params: {} }],
    ['today sales', { tool: 'reports', function: 'today', params: {} }],
    ['best selling product', { tool: 'reports', function: 'bestSeller', params: {} }],
    ['customer count', { tool: 'customer', function: 'count', params: {} }],
    ['merchant', { tool: 'settings', function: 'store', params: {} }],
  ])('routes "%s" correctly', (message, expected) => {
    expect(detectIntent(message)).toEqual(expected);
  });

  describe('inventory', () => {
    it('extracts a barcode', () => {
      expect(detectIntent('barcode 8901030875021')).toEqual({
        tool: 'inventory',
        function: 'barcodeSearch',
        params: { barcode: '8901030875021' },
      });
    });

    it('extracts a category', () => {
      expect(detectIntent('category surfboards')).toEqual({
        tool: 'inventory',
        function: 'categorySearch',
        params: { category: 'surfboards' },
      });
    });

    it('extracts a product query for a details lookup', () => {
      expect(detectIntent('tell me about Wax')).toEqual({
        tool: 'inventory',
        function: 'details',
        params: { query: 'Wax' },
      });
    });

    it('routes "out of stock" and "inventory value"', () => {
      expect(detectIntent('what is out of stock')).toEqual({
        tool: 'inventory',
        function: 'outOfStock',
        params: {},
      });
      expect(detectIntent('total inventory value')).toEqual({
        tool: 'inventory',
        function: 'inventoryValue',
        params: {},
      });
    });
  });

  describe('disambiguation between overlapping phrases', () => {
    it('routes "revenue today" to dashboard, not the bare reports.revenue pattern', () => {
      expect(detectIntent('revenue today')).toEqual({
        tool: 'dashboard',
        function: 'revenueToday',
        params: {},
      });
    });

    it('still routes a bare "revenue" question to reports', () => {
      expect(detectIntent('what is my revenue')).toEqual({
        tool: 'reports',
        function: 'revenue',
        params: {},
      });
    });

    it('routes "merchant name" to settings.merchantName, not the bare merchant/store pattern', () => {
      expect(detectIntent('what is my merchant name')).toEqual({
        tool: 'settings',
        function: 'merchantName',
        params: {},
      });
    });

    it('routes "customers today" to dashboard, not customer.count', () => {
      expect(detectIntent('customers today')).toEqual({
        tool: 'dashboard',
        function: 'customersToday',
        params: {},
      });
    });
  });

  describe('reports/dashboard/customer/billing keyword routing', () => {
    it.each([
      ['weekly sales', { tool: 'reports', function: 'weekly', params: {} }],
      ['monthly sales', { tool: 'reports', function: 'monthly', params: {} }],
      ['top category', { tool: 'reports', function: 'topCategory', params: {} }],
      ['average order value', { tool: 'reports', function: 'averageOrder', params: {} }],
      ['orders today', { tool: 'reports', function: 'ordersToday', params: {} }],
      ['business insights', { tool: 'dashboard', function: 'businessInsights', params: {} }],
      ['top customer', { tool: 'customer', function: 'topCustomer', params: {} }],
      ['recent customer', { tool: 'customer', function: 'recentCustomer', params: {} }],
      ['current cart', { tool: 'billing', function: 'currentCart', params: {} }],
      ['cart total', { tool: 'billing', function: 'cartTotal', params: {} }],
      ['item count', { tool: 'billing', function: 'itemCount', params: {} }],
      ['app version', { tool: 'settings', function: 'appVersion', params: {} }],
      ['theme', { tool: 'settings', function: 'theme', params: {} }],
      ['printer status', { tool: 'settings', function: 'printerStatus', params: {} }],
    ])('routes "%s"', (message, expected) => {
      expect(detectIntent(message)).toEqual(expected);
    });
  });

  describe('Phase AI-3 completions — reports/dashboard/customer/billing', () => {
    it.each([
      ['revenue summary', { tool: 'reports', function: 'revenueSummary', params: {} }],
      ['sales trend', { tool: 'reports', function: 'salesTrend', params: {} }],
      ['payment breakdown', { tool: 'reports', function: 'paymentBreakdown', params: {} }],
      ['inventory health', { tool: 'reports', function: 'inventoryHealth', params: {} }],
      ['kpi metrics', { tool: 'reports', function: 'kpiMetrics', params: {} }],
      ['key metrics', { tool: 'reports', function: 'kpiMetrics', params: {} }],
      ['growth', { tool: 'dashboard', function: 'growth', params: {} }],
      ['quick statistics', { tool: 'dashboard', function: 'quickStatistics', params: {} }],
      ['quick stats', { tool: 'dashboard', function: 'quickStatistics', params: {} }],
      ['customer statistics', { tool: 'customer', function: 'customerStatistics', params: {} }],
      ['current products', { tool: 'billing', function: 'currentProducts', params: {} }],
      ['grand total', { tool: 'billing', function: 'grandTotal', params: {} }],
      ['discount', { tool: 'billing', function: 'discount', params: {} }],
      ['tax', { tool: 'billing', function: 'tax', params: {} }],
    ])('routes "%s"', (message, expected) => {
      expect(detectIntent(message)).toEqual(expected);
    });

    it('"revenue summary" does not get shadowed by the bare revenue pattern', () => {
      expect(detectIntent('revenue summary')).toEqual({
        tool: 'reports',
        function: 'revenueSummary',
        params: {},
      });
      // The bare pattern still works on its own.
      expect(detectIntent('what is my revenue')).toEqual({
        tool: 'reports',
        function: 'revenue',
        params: {},
      });
    });
  });

  describe('navigation (Phase AI-3) — always checked before any tool', () => {
    it.each([
      ['open billing', { tool: 'navigation', function: 'openBilling', params: {} }],
      ['open inventory', { tool: 'navigation', function: 'openInventory', params: {} }],
      ['open reports', { tool: 'navigation', function: 'openReports', params: {} }],
      ['open customers', { tool: 'navigation', function: 'openCustomers', params: {} }],
      ['open settings', { tool: 'navigation', function: 'openSettings', params: {} }],
      ['open dashboard', { tool: 'navigation', function: 'openDashboard', params: {} }],
      ['open add product', { tool: 'navigation', function: 'openAddProduct', params: {} }],
      ['start new sale', { tool: 'navigation', function: 'startNewSale', params: {} }],
      ['new sale', { tool: 'navigation', function: 'startNewSale', params: {} }],
      ['generate demo data', { tool: 'navigation', function: 'generateDemoData', params: {} }],
      ['generate demo business', { tool: 'navigation', function: 'generateDemoData', params: {} }],
    ])('routes "%s"', (message, expected) => {
      expect(detectIntent(message)).toEqual(expected);
    });

    it('routes a bare "search <product>" to navigation.searchInventory, extracting the query', () => {
      expect(detectIntent('search Coca Cola')).toEqual({
        tool: 'navigation',
        function: 'searchInventory',
        params: { query: 'Coca Cola' },
      });
    });

    it('does not let the generic search catch-all shadow the more specific customer/billing search patterns', () => {
      expect(detectIntent('search customer John')).toEqual({
        tool: 'customer',
        function: 'search',
        params: { query: 'John' },
      });
      expect(detectIntent('search item wax')).toEqual({
        tool: 'billing',
        function: 'searchItem',
        params: { query: 'wax' },
      });
    });

    it('"open add product" does not get shadowed by the openInventory pattern', () => {
      expect(detectIntent('open add product')).toEqual({
        tool: 'navigation',
        function: 'openAddProduct',
        params: {},
      });
    });
  });

  describe('Phase CRM-1 completions — customer commands', () => {
    it.each([
      ['vip customers', { tool: 'customer', function: 'vipCustomers', params: {} }],
      ['customer loyalty', { tool: 'customer', function: 'loyalty', params: {} }],
      ['customer points', { tool: 'customer', function: 'loyalty', params: {} }],
    ])('routes "%s"', (message, expected) => {
      expect(detectIntent(message)).toEqual(expected);
    });

    it('extracts a name from "customer loyalty <name>"/"customer points for <name>"', () => {
      expect(detectIntent('customer loyalty John Smith')).toEqual({
        tool: 'customer',
        function: 'loyalty',
        params: { query: 'John Smith' },
      });
      expect(detectIntent('customer points for John Smith')).toEqual({
        tool: 'customer',
        function: 'loyalty',
        params: { query: 'John Smith' },
      });
    });

    it('routes "show customer <name>" to the same customer.search as "search customer <name>"', () => {
      expect(detectIntent('show customer John')).toEqual({
        tool: 'customer',
        function: 'search',
        params: { query: 'John' },
      });
    });

    it('"vip customers" is not shadowed by the bare customer.count pattern', () => {
      expect(detectIntent('vip customers')).toEqual({
        tool: 'customer',
        function: 'vipCustomers',
        params: {},
      });
    });
  });
});
