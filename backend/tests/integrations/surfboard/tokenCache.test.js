import { describe, it, expect, vi } from 'vitest';
import TokenCache from '../../../src/integrations/surfboard/cache/tokenCache.js';

describe('TokenCache', () => {
  it('returns undefined for a missing key', () => {
    const cache = new TokenCache();
    expect(cache.get('missing')).toBeUndefined();
  });

  it('returns a stored value before it expires', () => {
    const cache = new TokenCache();
    cache.set('key', 'token-value', Date.now() + 10_000);
    expect(cache.get('key')).toBe('token-value');
  });

  it('treats an expired entry as a cache miss and evicts it', () => {
    const cache = new TokenCache();
    cache.set('key', 'token-value', Date.now() - 1);
    expect(cache.get('key')).toBeUndefined();
  });

  it('clear() removes a single key without touching others', () => {
    const cache = new TokenCache();
    cache.set('a', 'A', Date.now() + 10_000);
    cache.set('b', 'B', Date.now() + 10_000);
    cache.clear('a');
    expect(cache.get('a')).toBeUndefined();
    expect(cache.get('b')).toBe('B');
  });

  it('getOrCreate() calls factory once on a miss and caches the result', async () => {
    const cache = new TokenCache();
    const factory = vi.fn().mockResolvedValue({ value: 'fresh', expiresAt: Date.now() + 10_000 });

    const first = await cache.getOrCreate('key', factory);
    const second = await cache.getOrCreate('key', factory);

    expect(first).toBe('fresh');
    expect(second).toBe('fresh');
    expect(factory).toHaveBeenCalledTimes(1);
  });

  it('getOrCreate() single-flights concurrent calls into one factory invocation', async () => {
    const cache = new TokenCache();
    let resolveFactory;
    const factory = vi.fn(
      () =>
        new Promise((resolve) => {
          resolveFactory = resolve;
        }),
    );

    const call1 = cache.getOrCreate('key', factory);
    const call2 = cache.getOrCreate('key', factory);

    resolveFactory({ value: 'shared', expiresAt: Date.now() + 10_000 });

    await expect(call1).resolves.toBe('shared');
    await expect(call2).resolves.toBe('shared');
    expect(factory).toHaveBeenCalledTimes(1);
  });

  it('getOrCreate() re-invokes factory once the cached value expires', async () => {
    const cache = new TokenCache();
    const factory = vi
      .fn()
      .mockResolvedValueOnce({ value: 'first', expiresAt: Date.now() - 1 })
      .mockResolvedValueOnce({ value: 'second', expiresAt: Date.now() + 10_000 });

    await cache.getOrCreate('key', factory);
    const second = await cache.getOrCreate('key', factory);

    expect(second).toBe('second');
    expect(factory).toHaveBeenCalledTimes(2);
  });
});
