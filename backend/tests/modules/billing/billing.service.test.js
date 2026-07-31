import { describe, it, expect, vi } from 'vitest';
import { createBillingService } from '../../../src/modules/billing/billing.service.js';

function createFakeInventoryService(overrides = {}) {
  return {
    getProduct: vi.fn().mockResolvedValue({
      id: 'p1',
      name: 'Wax',
      sellingPrice: 100,
      taxRate: 25,
      discountPercentage: 0,
    }),
    ...overrides,
  };
}

describe('billing.service', () => {
  describe('resolveCheckoutItems', () => {
    it('resolves price/tax/discount from Inventory, ignoring any client-submitted values', async () => {
      const inventoryService = createFakeInventoryService();
      const service = createBillingService({ inventoryService });

      // A client could send anything here beyond productId/quantity — the validator already
      // strips it, but this proves the service itself never reads it either.
      const result = await service.resolveCheckoutItems('uid_1', 'store_1', [
        { productId: 'p1', quantity: 2, unitPrice: 1, taxPercentage: 0, discountPercentage: 100 },
      ]);

      expect(inventoryService.getProduct).toHaveBeenCalledWith('uid_1', 'p1', { storeId: 'store_1' });
      expect(result.items).toEqual([
        {
          productId: 'p1',
          name: 'Wax',
          quantity: 2,
          unitPrice: 100,
          taxPercentage: 25,
          discountPercentage: 0,
        },
      ]);
    });

    it('computes subtotal/discountTotal/taxTotal/grandTotal across multiple lines with different rates', async () => {
      const inventoryService = createFakeInventoryService({
        getProduct: vi
          .fn()
          .mockResolvedValueOnce({
            id: 'p1',
            name: 'Wax',
            sellingPrice: 100,
            taxRate: 10,
            discountPercentage: 0,
          })
          .mockResolvedValueOnce({
            id: 'p2',
            name: 'Leash',
            sellingPrice: 50,
            taxRate: 20,
            discountPercentage: 10,
          }),
      });
      const service = createBillingService({ inventoryService });

      const result = await service.resolveCheckoutItems('uid_1', 'store_1', [
        { productId: 'p1', quantity: 1 },
        { productId: 'p2', quantity: 2 },
      ]);

      // p1: subtotal 100, discount 0, tax 10 -> total 110
      // p2: subtotal 100, discount 10, tax 18 (20% of 90) -> total 108
      expect(result.subtotal).toBe(200);
      expect(result.discountTotal).toBe(10);
      expect(result.taxTotal).toBe(28);
      expect(result.grandTotal).toBe(218);
    });

    it('throws ValidationError for an empty cart', async () => {
      const service = createBillingService({ inventoryService: createFakeInventoryService() });

      await expect(service.resolveCheckoutItems('uid_1', 'store_1', [])).rejects.toMatchObject({
        name: 'ValidationError',
        code: 'VALIDATION_ERROR',
      });
    });

    it('propagates NotFoundError when a product does not exist or is not owned by this merchant', async () => {
      const notFound = Object.assign(new Error('Product not found'), {
        name: 'NotFoundError',
        code: 'NOT_FOUND',
      });
      const inventoryService = createFakeInventoryService({
        getProduct: vi.fn().mockRejectedValue(notFound),
      });
      const service = createBillingService({ inventoryService });

      await expect(
        service.resolveCheckoutItems('uid_1', 'store_1', [{ productId: 'missing', quantity: 1 }]),
      ).rejects.toBe(notFound);
    });
  });
});
