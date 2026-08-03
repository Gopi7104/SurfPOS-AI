import { describe, it, expect, vi } from 'vitest';
import { createSalesLedgerService } from '../../../src/modules/reports/salesLedger.service.js';

function createFakeSalesLedgerRepository(overrides = {}) {
  return {
    getSales: vi.fn().mockResolvedValue([]),
    setSales: vi.fn().mockImplementation((merchantId, records) => Promise.resolve(records)),
    ...overrides,
  };
}

function createFakeMerchantService(overrides = {}) {
  return { getMerchantId: vi.fn().mockResolvedValue('merchant_1'), ...overrides };
}

describe('salesLedger.service', () => {
  it('resolves merchantId before reading the ledger', async () => {
    const salesLedgerRepository = createFakeSalesLedgerRepository({
      getSales: vi.fn().mockResolvedValue([{ id: 'sale_1' }]),
    });
    const merchantService = createFakeMerchantService();
    const service = createSalesLedgerService({ salesLedgerRepository, merchantService });

    const result = await service.getSales('uid_1');

    expect(merchantService.getMerchantId).toHaveBeenCalledWith('uid_1');
    expect(salesLedgerRepository.getSales).toHaveBeenCalledWith('merchant_1');
    expect(result).toEqual([{ id: 'sale_1' }]);
  });

  it('resolves merchantId before overwriting the whole ledger', async () => {
    const salesLedgerRepository = createFakeSalesLedgerRepository();
    const merchantService = createFakeMerchantService();
    const service = createSalesLedgerService({ salesLedgerRepository, merchantService });

    const records = [{ id: 'sale_1' }, { id: 'sale_2' }];
    const result = await service.setSales('uid_1', records);

    expect(salesLedgerRepository.setSales).toHaveBeenCalledWith('merchant_1', records);
    expect(result).toEqual(records);
  });
});
