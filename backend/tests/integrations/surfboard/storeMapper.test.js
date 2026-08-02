import { describe, it, expect } from 'vitest';
import storeMapper from '../../../src/integrations/surfboard/mappers/store.mapper.js';

describe('storeMapper.toWire', () => {
  it('maps the domain create input to Surfboard wire field names', () => {
    const wire = storeMapper.toWire({
      merchantId: 'sb_merchant_1',
      name: 'Main Store',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
    });

    expect(wire).toEqual({
      merchant_id: 'sb_merchant_1',
      name: 'Main Store',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
    });
  });
});

describe('storeMapper.toDomain', () => {
  it('maps a full Surfboard response to the domain Store shape', () => {
    const store = storeMapper.toDomain({
      status: 'SUCCESS',
      data: {
        storeId: 'sb_store_1',
        merchantId: 'sb_merchant_1',
        name: 'Main Store',
        address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
        capabilities: { supportedPaymentMethods: ['card'], tipsEnabled: true },
        status: 'active',
      },
    });

    expect(store).toEqual({
      id: 'sb_store_1',
      merchantId: 'sb_merchant_1',
      name: 'Main Store',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
      capabilities: { supportedPaymentMethods: ['card'], tipsEnabled: true },
      status: 'active',
      onlineInfo: null,
    });
  });

  it('surfaces onlineInfo when present — the field ensureStoreOnlineInfo() checks', () => {
    const store = storeMapper.toDomain({
      status: 'SUCCESS',
      data: {
        storeId: 'sb_store_1',
        onlineInfo: { merchantWebshopURL: 'https://example.com' },
      },
    });

    expect(store.onlineInfo).toEqual({ merchantWebshopURL: 'https://example.com' });
  });

  it('defaults missing fields to null rather than throwing', () => {
    expect(storeMapper.toDomain({})).toEqual({
      id: null,
      merchantId: null,
      name: null,
      address: null,
      capabilities: null,
      status: null,
      onlineInfo: null,
    });
  });
});

describe('storeMapper.toUpdateWire', () => {
  it("maps domain field names to Surfboard's confirmed Update Store Details wire names", () => {
    expect(storeMapper.toUpdateWire({ name: 'New Name' })).toEqual({ storeName: 'New Name' });
  });

  it('passes onlineInfo through as-is (already in Surfboard wire shape)', () => {
    const onlineInfo = {
      merchantWebshopURL: 'https://example.com',
      termsAndConditionsURL: 'https://example.com/terms',
      privacyPolicyURL: 'https://example.com/privacy',
    };
    expect(storeMapper.toUpdateWire({ onlineInfo })).toEqual({ onlineInfo });
  });

  it('returns an empty object for an empty patch', () => {
    expect(storeMapper.toUpdateWire({})).toEqual({});
  });
});
