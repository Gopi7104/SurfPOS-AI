import { describe, it, expect } from 'vitest';
import { createTokenRefreshStrategy } from '../../../src/integrations/surfboard/provider/tokenRefreshStrategy.js';

describe('createTokenRefreshStrategy', () => {
  it('subtracts the refresh skew from the hard expiry', () => {
    const strategy = createTokenRefreshStrategy({ refreshSkewMs: 5_000 });
    const now = 1_000_000;

    expect(strategy.computeCacheExpiry(60, now)).toBe(now + 60_000 - 5_000);
  });

  it('never returns an expiry before now, even if skew exceeds the token lifetime', () => {
    const strategy = createTokenRefreshStrategy({ refreshSkewMs: 30_000 });
    const now = 1_000_000;

    expect(strategy.computeCacheExpiry(5, now)).toBe(now);
  });

  it('defaults to a 30s skew when none is provided', () => {
    const strategy = createTokenRefreshStrategy();
    expect(strategy.refreshSkewMs).toBe(30_000);
  });
});
