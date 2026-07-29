import { describe, it, expect, vi } from 'vitest';
import TokenProvider from '../../../src/integrations/surfboard/provider/tokenProvider.js';

describe('TokenProvider', () => {
  it('throws if constructed without a fetchToken function', () => {
    expect(() => new TokenProvider({})).toThrow(TypeError);
  });

  it('fetches and returns a token on the first call', async () => {
    const fetchToken = vi.fn().mockResolvedValue({ token: 'tok_1', expiresInSeconds: 60 });
    const provider = new TokenProvider({ fetchToken });

    await expect(provider.getToken()).resolves.toBe('tok_1');
    expect(fetchToken).toHaveBeenCalledTimes(1);
  });

  it('caches the token across calls instead of re-fetching', async () => {
    const fetchToken = vi.fn().mockResolvedValue({ token: 'tok_1', expiresInSeconds: 60 });
    const provider = new TokenProvider({ fetchToken });

    await provider.getToken();
    await provider.getToken();
    await provider.getToken();

    expect(fetchToken).toHaveBeenCalledTimes(1);
  });

  it('re-fetches once the token is past its refresh skew window', async () => {
    const fetchToken = vi
      .fn()
      .mockResolvedValueOnce({ token: 'tok_1', expiresInSeconds: 0.03 })
      .mockResolvedValueOnce({ token: 'tok_2', expiresInSeconds: 60 });
    const provider = new TokenProvider({
      fetchToken,
      refreshStrategy: { computeCacheExpiry: (secs, now = Date.now()) => now + secs * 1000 },
    });

    await expect(provider.getToken()).resolves.toBe('tok_1');
    await new Promise((resolve) => setTimeout(resolve, 50));
    await expect(provider.getToken()).resolves.toBe('tok_2');
    expect(fetchToken).toHaveBeenCalledTimes(2);
  });

  it('invalidate() forces the next getToken() to fetch a fresh token', async () => {
    const fetchToken = vi
      .fn()
      .mockResolvedValueOnce({ token: 'tok_1', expiresInSeconds: 60 })
      .mockResolvedValueOnce({ token: 'tok_2', expiresInSeconds: 60 });
    const provider = new TokenProvider({ fetchToken });

    await provider.getToken();
    provider.invalidate();
    const second = await provider.getToken();

    expect(second).toBe('tok_2');
    expect(fetchToken).toHaveBeenCalledTimes(2);
  });

  it('single-flights concurrent getToken() calls into one fetchToken() invocation', async () => {
    let resolveFetch;
    const fetchToken = vi.fn(
      () =>
        new Promise((resolve) => {
          resolveFetch = resolve;
        }),
    );
    const provider = new TokenProvider({ fetchToken });

    const call1 = provider.getToken();
    const call2 = provider.getToken();
    resolveFetch({ token: 'tok_shared', expiresInSeconds: 60 });

    await expect(call1).resolves.toBe('tok_shared');
    await expect(call2).resolves.toBe('tok_shared');
    expect(fetchToken).toHaveBeenCalledTimes(1);
  });
});
