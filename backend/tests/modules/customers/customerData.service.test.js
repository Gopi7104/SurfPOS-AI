import { describe, it, expect, vi } from 'vitest';
import { createCustomerDataService } from '../../../src/modules/customers/customerData.service.js';

function createFakeCustomerDataRepository(overrides = {}) {
  return {
    getCustomers: vi.fn().mockResolvedValue([]),
    setCustomers: vi.fn().mockImplementation((merchantId, customers) => Promise.resolve(customers)),
    getPurchases: vi.fn().mockResolvedValue([]),
    setPurchases: vi.fn().mockImplementation((merchantId, purchases) => Promise.resolve(purchases)),
    ...overrides,
  };
}

function createFakeMerchantService(overrides = {}) {
  return { getMerchantId: vi.fn().mockResolvedValue('merchant_1'), ...overrides };
}

describe('customerData.service', () => {
  it('resolves merchantId before reading customers', async () => {
    const customerDataRepository = createFakeCustomerDataRepository({
      getCustomers: vi.fn().mockResolvedValue([{ id: 'CUST-1' }]),
    });
    const merchantService = createFakeMerchantService();
    const service = createCustomerDataService({ customerDataRepository, merchantService });

    const result = await service.getCustomers('uid_1');

    expect(merchantService.getMerchantId).toHaveBeenCalledWith('uid_1');
    expect(customerDataRepository.getCustomers).toHaveBeenCalledWith('merchant_1');
    expect(result).toEqual([{ id: 'CUST-1' }]);
  });

  it('resolves merchantId before overwriting the whole customer list', async () => {
    const customerDataRepository = createFakeCustomerDataRepository();
    const merchantService = createFakeMerchantService();
    const service = createCustomerDataService({ customerDataRepository, merchantService });

    const customers = [{ id: 'CUST-1' }, { id: 'CUST-2' }];
    const result = await service.setCustomers('uid_1', customers);

    expect(customerDataRepository.setCustomers).toHaveBeenCalledWith('merchant_1', customers);
    expect(result).toEqual(customers);
  });

  it('resolves merchantId before reading/writing purchase history', async () => {
    const customerDataRepository = createFakeCustomerDataRepository();
    const merchantService = createFakeMerchantService();
    const service = createCustomerDataService({ customerDataRepository, merchantService });

    await service.getPurchases('uid_1');
    expect(customerDataRepository.getPurchases).toHaveBeenCalledWith('merchant_1');

    const purchases = [{ customerId: 'CUST-1', receiptNumber: 'RCPT-1' }];
    await service.setPurchases('uid_1', purchases);
    expect(customerDataRepository.setPurchases).toHaveBeenCalledWith('merchant_1', purchases);
  });
});
