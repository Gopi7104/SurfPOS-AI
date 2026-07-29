import { describe, it, expect, vi } from 'vitest';
import AuthenticationManager from '../../../src/integrations/surfboard/auth/authenticationManager.js';

describe('AuthenticationManager', () => {
  it('defaults to the api_key strategy when none is configured', async () => {
    const manager = new AuthenticationManager({ config: { apiKey: 'key_123' } });
    await expect(manager.getAuthHeaders()).resolves.toEqual({ Authorization: 'Bearer key_123' });
  });

  it('selects the bearer strategy when configured', async () => {
    const manager = new AuthenticationManager({
      config: { authStrategy: 'bearer', bearerToken: 'tok_456' },
    });
    await expect(manager.getAuthHeaders()).resolves.toEqual({ Authorization: 'Bearer tok_456' });
  });

  it('selects the oauth strategy when configured, given valid credentials', async () => {
    const manager = new AuthenticationManager({
      config: {
        authStrategy: 'oauth',
        apiKey: 'key_123',
        apiSecret: 'secret_456',
        baseUrl: 'https://sandbox.example.test',
      },
    });
    expect(manager.strategy.constructor.name).toBe('OAuthStrategy');
  });

  it('throws a SurfboardAuthConfigError when required credentials are missing', () => {
    expect(() => new AuthenticationManager({ config: { authStrategy: 'bearer' } })).toThrow(
      /SURFBOARD_AUTH_STRATEGY=bearer requires SURFBOARD_BEARER_TOKEN/,
    );
  });

  it('throws for an unregistered strategy name', () => {
    expect(
      () => new AuthenticationManager({ config: { authStrategy: 'carrier_pigeon', apiKey: 'x' } }),
    ).toThrow();
  });

  it('supports injecting custom strategy factories for testing/extension', async () => {
    const fakeStrategy = { getAuthHeaders: vi.fn().mockResolvedValue({ 'X-Fake': 'yes' }) };
    const manager = new AuthenticationManager({
      config: { authStrategy: 'fake' },
      strategyFactories: { fake: () => fakeStrategy },
    });

    await expect(manager.getAuthHeaders()).resolves.toEqual({ 'X-Fake': 'yes' });
  });

  it('rejects an injected strategy that does not implement getAuthHeaders()', () => {
    expect(
      () =>
        new AuthenticationManager({
          config: { authStrategy: 'api_key', apiKey: 'key_123' },
          strategyFactories: { api_key: () => ({}) },
        }),
    ).toThrow(TypeError);
  });
});
