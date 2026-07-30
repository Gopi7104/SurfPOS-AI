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
      store_id: 'sb_store_1',
      merchant_id: 'sb_merchant_1',
      name: 'Main Store',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
      capabilities: { supportedPaymentMethods: ['card'], tipsEnabled: true },
      status: 'active',
    });

    expect(store).toEqual({
      id: 'sb_store_1',
      merchantId: 'sb_merchant_1',
      name: 'Main Store',
      address: { line1: 'Main St 1', city: 'Malmö', country: 'SE' },
      capabilities: { supportedPaymentMethods: ['card'], tipsEnabled: true },
      status: 'active',
    });
  });

  it('defaults missing fields to null rather than throwing', () => {
    expect(storeMapper.toDomain({})).toEqual({
      id: null,
      merchantId: null,
      name: null,
      address: null,
      capabilities: null,
      status: null,
    });
  });
});

describe('storeMapper.toUpdateWire', () => {
  it('only includes fields that were provided', () => {
    expect(storeMapper.toUpdateWire({ name: 'New Name' })).toEqual({ name: 'New Name' });
  });

  it('returns an empty object for an empty patch', () => {
    expect(storeMapper.toUpdateWire({})).toEqual({});
  });
});
