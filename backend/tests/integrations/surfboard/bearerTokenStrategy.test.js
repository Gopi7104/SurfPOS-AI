import { describe, it, expect, vi } from 'vitest';
import BearerTokenStrategy from '../../../src/integrations/surfboard/auth/strategies/bearerTokenStrategy.js';
import TokenProvider from '../../../src/integrations/surfboard/provider/tokenProvider.js';

describe('BearerTokenStrategy', () => {
  it('throws if constructed without a bearerToken, fetchToken, or tokenProvider', () => {
    expect(() => new BearerTokenStrategy({})).toThrow(TypeError);
  });

  it('attaches a static bearer token as an Authorization header', async () => {
    const strategy = new BearerTokenStrategy({ bearerToken: 'static_tok' });
    await expect(strategy.getAuthHeaders()).resolves.toEqual({ Authorization: 'Bearer static_tok' });
  });

  it('sources the token from a custom fetchToken()', async () => {
    const fetchToken = vi.fn().mockResolvedValue({ token: 'dynamic_tok', expiresInSeconds: 60 });
    const strategy = new BearerTokenStrategy({ fetchToken });

    await expect(strategy.getAuthHeaders()).resolves.toEqual({ Authorization: 'Bearer dynamic_tok' });
    await strategy.getAuthHeaders();
    expect(fetchToken).toHaveBeenCalledTimes(1);
  });

  it('accepts a pre-built tokenProvider', async () => {
    const fetchToken = vi.fn().mockResolvedValue({ token: 'injected_tok', expiresInSeconds: 60 });
    const tokenProvider = new TokenProvider({ fetchToken });
    const strategy = new BearerTokenStrategy({ tokenProvider });

    await expect(strategy.getAuthHeaders()).resolves.toEqual({ Authorization: 'Bearer injected_tok' });
  });
});
