import { describe, it, expect, vi } from 'vitest';
import { createSettingsTool } from '../../../../src/modules/ai/tools/settings.tool.js';

describe('settings.tool', () => {
  describe('store (real data)', () => {
    it('reports the store name and status', async () => {
      const storeService = {
        getPrimaryStoreId: vi.fn().mockResolvedValue('store-1'),
        getStore: vi.fn().mockResolvedValue({ name: 'Downtown Surf', status: 'ACTIVE' }),
      };
      const tool = createSettingsTool({ storeService });

      const result = await tool.store('uid-1');

      expect(result.available).toBe(true);
      expect(result.message).toContain('Downtown Surf');
      expect(result.message).toContain('ACTIVE');
    });

    it('is honest when the merchant has no store yet', async () => {
      const storeService = { getPrimaryStoreId: vi.fn().mockResolvedValue(null) };
      const tool = createSettingsTool({ storeService });

      const result = await tool.store('uid-1');

      expect(result).toEqual({ available: true, message: "You don't have a store set up yet." });
    });
  });

  describe('merchantName (real data)', () => {
    it('reports the merchant name', async () => {
      const merchantService = { getMerchantDetails: vi.fn().mockResolvedValue({ name: 'Acme Surf Co' }) };
      const tool = createSettingsTool({ merchantService });

      const result = await tool.merchantName('uid-1');

      expect(result.available).toBe(true);
      expect(result.message).toContain('Acme Surf Co');
    });
  });

  describe('app-level concepts with no backend record', () => {
    it('appVersion is honestly unavailable', async () => {
      const tool = createSettingsTool();
      const result = await tool.appVersion();
      expect(result.available).toBe(false);
    });

    it('theme is honestly unavailable', async () => {
      const tool = createSettingsTool();
      const result = await tool.theme();
      expect(result.available).toBe(false);
    });

    it('printerStatus is honestly unavailable', async () => {
      const tool = createSettingsTool();
      const result = await tool.printerStatus();
      expect(result.available).toBe(false);
    });
  });
});
