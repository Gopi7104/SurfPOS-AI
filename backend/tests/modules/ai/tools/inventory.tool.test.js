import { describe, it, expect, vi } from 'vitest';
import { createInventoryTool } from '../../../../src/modules/ai/tools/inventory.tool.js';

const PRODUCT_A = {
  id: 'p1',
  name: 'Wax',
  sku: 'WAX-1',
  category: 'Accessories',
  sellingPrice: 12.5,
  stockQuantity: 30,
};
const PRODUCT_B = {
  id: 'p2',
  name: 'Leash',
  sku: 'LSH-1',
  category: 'Accessories',
  sellingPrice: 25,
  stockQuantity: 2,
};

function createFakeInventoryService(overrides = {}) {
  return {
    listProducts: vi.fn().mockResolvedValue({ items: [], nextCursor: null }),
    ...overrides,
  };
}

describe('inventory.tool', () => {
  describe('search', () => {
    it('lists matching products with price and stock', async () => {
      const inventoryService = createFakeInventoryService({
        listProducts: vi.fn().mockResolvedValue({ items: [PRODUCT_A], nextCursor: null }),
      });
      const tool = createInventoryTool({ inventoryService });

      const result = await tool.search('uid-1', { query: 'wax' });

      expect(inventoryService.listProducts).toHaveBeenCalledWith('uid-1', { search: 'wax', limit: 8 });
      expect(result.available).toBe(true);
      expect(result.message).toContain('Wax');
      expect(result.message).toContain('$12.50');
      expect(result.message).toContain('30 in stock');
    });

    it('reports no matches honestly instead of an empty list', async () => {
      const tool = createInventoryTool({ inventoryService: createFakeInventoryService() });

      const result = await tool.search('uid-1', { query: 'nonexistent' });

      expect(result).toEqual({ available: true, message: 'No products found matching "nonexistent".' });
    });
  });

  describe('details', () => {
    it('returns full details for the first match', async () => {
      const inventoryService = createFakeInventoryService({
        listProducts: vi.fn().mockResolvedValue({ items: [PRODUCT_A], nextCursor: null }),
      });
      const tool = createInventoryTool({ inventoryService });

      const result = await tool.details('uid-1', { query: 'wax' });

      expect(result.available).toBe(true);
      expect(result.message).toContain('WAX-1');
      expect(result.message).toContain('Accessories');
    });

    it('asks for a query when none was given', async () => {
      const tool = createInventoryTool({ inventoryService: createFakeInventoryService() });
      const result = await tool.details('uid-1', {});
      expect(result.message).toMatch(/which product/i);
    });
  });

  describe('lowStock / outOfStock', () => {
    it('lowStock filters by stockFilter: lowStock', async () => {
      const inventoryService = createFakeInventoryService({
        listProducts: vi.fn().mockResolvedValue({ items: [PRODUCT_B], nextCursor: null }),
      });
      const tool = createInventoryTool({ inventoryService });

      const result = await tool.lowStock('uid-1');

      expect(inventoryService.listProducts).toHaveBeenCalledWith('uid-1', {
        stockFilter: 'lowStock',
        limit: 8,
      });
      expect(result.message).toContain('Leash');
    });

    it('reports nothing running low when the list is empty', async () => {
      const tool = createInventoryTool({ inventoryService: createFakeInventoryService() });
      const result = await tool.lowStock('uid-1');
      expect(result).toEqual({ available: true, message: 'Nothing is running low right now.' });
    });

    it('outOfStock reports nothing out of stock when the list is empty', async () => {
      const tool = createInventoryTool({ inventoryService: createFakeInventoryService() });
      const result = await tool.outOfStock('uid-1');
      expect(result).toEqual({ available: true, message: 'Nothing is out of stock right now.' });
    });
  });

  describe('count / inventoryValue', () => {
    it('count walks every page and sums the total', async () => {
      const listProducts = vi
        .fn()
        .mockResolvedValueOnce({ items: [PRODUCT_A], nextCursor: 'p1' })
        .mockResolvedValueOnce({ items: [PRODUCT_B], nextCursor: null });
      const tool = createInventoryTool({ inventoryService: { listProducts } });

      const result = await tool.count('uid-1');

      expect(listProducts).toHaveBeenCalledTimes(2);
      expect(result).toEqual({ available: true, message: 'You have 2 product(s) in your inventory.' });
    });

    it('inventoryValue sums sellingPrice × stockQuantity across the whole catalog', async () => {
      const inventoryService = createFakeInventoryService({
        listProducts: vi.fn().mockResolvedValue({ items: [PRODUCT_A, PRODUCT_B], nextCursor: null }),
      });
      const tool = createInventoryTool({ inventoryService });

      const result = await tool.inventoryValue('uid-1');

      // 12.5 * 30 + 25 * 2 = 375 + 50 = 425
      expect(result).toEqual({
        available: true,
        message: 'Your current inventory is worth $425.00 at selling price, across 2 product(s).',
      });
    });
  });

  describe('barcodeSearch / categorySearch', () => {
    it('barcodeSearch looks up an exact barcode', async () => {
      const inventoryService = createFakeInventoryService({
        listProducts: vi.fn().mockResolvedValue({ items: [PRODUCT_A], nextCursor: null }),
      });
      const tool = createInventoryTool({ inventoryService });

      const result = await tool.barcodeSearch('uid-1', { barcode: '12345' });

      expect(inventoryService.listProducts).toHaveBeenCalledWith('uid-1', { barcode: '12345', limit: 1 });
      expect(result.message).toContain('Wax');
    });

    it('barcodeSearch asks for a barcode when none was given', async () => {
      const tool = createInventoryTool({ inventoryService: createFakeInventoryService() });
      const result = await tool.barcodeSearch('uid-1', {});
      expect(result.message).toMatch(/what barcode/i);
    });

    it('categorySearch lists products in the given category', async () => {
      const inventoryService = createFakeInventoryService({
        listProducts: vi.fn().mockResolvedValue({ items: [PRODUCT_A, PRODUCT_B], nextCursor: null }),
      });
      const tool = createInventoryTool({ inventoryService });

      const result = await tool.categorySearch('uid-1', { category: 'Accessories' });

      expect(inventoryService.listProducts).toHaveBeenCalledWith('uid-1', {
        category: 'Accessories',
        limit: 8,
      });
      expect(result.message).toContain('2 product(s)');
    });
  });

  it('propagates an underlying service error untouched (ai.service.js turns it into a friendly reply)', async () => {
    const notFound = new Error('merchant reference not found');
    const inventoryService = createFakeInventoryService({
      listProducts: vi.fn().mockRejectedValue(notFound),
    });
    const tool = createInventoryTool({ inventoryService });

    await expect(tool.search('uid-1', { query: 'wax' })).rejects.toBe(notFound);
  });
});
