import { describe, it, expect } from 'vitest';
import BaseMapper from '../../../src/integrations/surfboard/mappers/baseMapper.js';

describe('BaseMapper', () => {
  it('throws when toDomain is not overridden', () => {
    const mapper = new BaseMapper();
    expect(() => mapper.toDomain({})).toThrow(/toDomain\(\) must be implemented/);
  });

  it('throws when toWire is not overridden', () => {
    const mapper = new BaseMapper();
    expect(() => mapper.toWire({})).toThrow(/toWire\(\) must be implemented/);
  });

  it('a subclass can override both methods', () => {
    class MerchantMapper extends BaseMapper {
      toDomain(raw) {
        return { id: raw.merchant_id };
      }

      toWire(domain) {
        return { merchant_id: domain.id };
      }
    }

    const mapper = new MerchantMapper();
    expect(mapper.toDomain({ merchant_id: 'sb_1' })).toEqual({ id: 'sb_1' });
    expect(mapper.toWire({ id: 'sb_1' })).toEqual({ merchant_id: 'sb_1' });
  });
});
