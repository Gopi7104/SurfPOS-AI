import { describe, it, expect } from 'vitest';
import ApiKeySecretStrategy from '../../../src/integrations/surfboard/auth/strategies/apiKeySecretStrategy.js';

describe('ApiKeySecretStrategy', () => {
  it('throws if constructed without an apiKey', () => {
    expect(() => new ApiKeySecretStrategy({ apiSecret: 'secret_123' })).toThrow(TypeError);
  });

  it('throws if constructed without an apiSecret', () => {
    expect(() => new ApiKeySecretStrategy({ apiKey: 'key_123' })).toThrow(TypeError);
  });

  it('sends both API-KEY and API-SECRET headers', async () => {
    const strategy = new ApiKeySecretStrategy({ apiKey: 'key_123', apiSecret: 'secret_123' });
    await expect(strategy.getAuthHeaders()).resolves.toEqual({
      'API-KEY': 'key_123',
      'API-SECRET': 'secret_123',
    });
  });
});
