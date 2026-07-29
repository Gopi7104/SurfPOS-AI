import { describe, it, expect } from 'vitest';
import ApiKeyStrategy from '../../../src/integrations/surfboard/auth/strategies/apiKeyStrategy.js';

describe('ApiKeyStrategy', () => {
  it('throws if constructed without an apiKey', () => {
    expect(() => new ApiKeyStrategy({})).toThrow(TypeError);
  });

  it('defaults to a Bearer-style Authorization header', async () => {
    const strategy = new ApiKeyStrategy({ apiKey: 'key_123' });
    await expect(strategy.getAuthHeaders()).resolves.toEqual({ Authorization: 'Bearer key_123' });
  });

  it('supports a custom header name and value formatter', async () => {
    const strategy = new ApiKeyStrategy({
      apiKey: 'key_123',
      headerName: 'X-Api-Key',
      formatValue: (key) => key,
    });

    await expect(strategy.getAuthHeaders()).resolves.toEqual({ 'X-Api-Key': 'key_123' });
  });
});
