import { describe, it, expect, vi } from 'vitest';
import OAuthStrategy from '../../../src/integrations/surfboard/auth/strategies/oauthStrategy.js';

function jsonResponse(data, { ok = true, status = 200 } = {}) {
  return { ok, status, json: async () => data };
}

describe('OAuthStrategy', () => {
  it('throws if constructed without apiKey/apiSecret', () => {
    expect(() => new OAuthStrategy({ baseUrl: 'https://sandbox.example.test' })).toThrow(TypeError);
  });

  it('requests a client-credentials token from the configured endpoint', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse({ access_token: 'oauth_tok', expires_in: 60 }));
    const strategy = new OAuthStrategy({
      baseUrl: 'https://sandbox.example.test',
      apiKey: 'key_123',
      apiSecret: 'secret_456',
      fetchImpl,
    });

    await expect(strategy.getAuthHeaders()).resolves.toEqual({ Authorization: 'Bearer oauth_tok' });

    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/oauth/token');
    const body = JSON.parse(init.body);
    expect(body).toEqual({
      grant_type: 'client_credentials',
      client_id: 'key_123',
      client_secret: 'secret_456',
    });
  });

  it('caches the token instead of requesting one per call', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse({ access_token: 'oauth_tok', expires_in: 60 }));
    const strategy = new OAuthStrategy({
      baseUrl: 'https://sandbox.example.test',
      apiKey: 'key_123',
      apiSecret: 'secret_456',
      fetchImpl,
    });

    await strategy.getAuthHeaders();
    await strategy.getAuthHeaders();

    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it('throws when the token endpoint responds with a non-ok status', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse({}, { ok: false, status: 401 }));
    const strategy = new OAuthStrategy({
      baseUrl: 'https://sandbox.example.test',
      apiKey: 'key_123',
      apiSecret: 'secret_456',
      fetchImpl,
    });

    await expect(strategy.getAuthHeaders()).rejects.toThrow(/401/);
  });
});
