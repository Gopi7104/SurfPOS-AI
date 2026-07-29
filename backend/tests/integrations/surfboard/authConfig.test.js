import { describe, it, expect } from 'vitest';
import {
  validateAuthConfig,
  SurfboardAuthConfigError,
} from '../../../src/integrations/surfboard/auth/authConfig.js';
import { STRATEGY_TYPES } from '../../../src/integrations/surfboard/auth/authStrategy.js';

describe('validateAuthConfig', () => {
  it('passes for api_key when an apiKey is present', () => {
    expect(() => validateAuthConfig(STRATEGY_TYPES.API_KEY, { apiKey: 'key' })).not.toThrow();
  });

  it('throws for api_key when apiKey is missing', () => {
    expect(() => validateAuthConfig(STRATEGY_TYPES.API_KEY, {})).toThrow(SurfboardAuthConfigError);
  });

  it('passes for bearer when a bearerToken is present', () => {
    expect(() => validateAuthConfig(STRATEGY_TYPES.BEARER, { bearerToken: 'tok' })).not.toThrow();
  });

  it('throws for bearer when bearerToken is missing', () => {
    expect(() => validateAuthConfig(STRATEGY_TYPES.BEARER, {})).toThrow(SurfboardAuthConfigError);
  });

  it('passes for oauth when both apiKey and apiSecret are present', () => {
    expect(() =>
      validateAuthConfig(STRATEGY_TYPES.OAUTH, { apiKey: 'key', apiSecret: 'secret' }),
    ).not.toThrow();
  });

  it('throws for oauth when apiSecret is missing', () => {
    expect(() => validateAuthConfig(STRATEGY_TYPES.OAUTH, { apiKey: 'key' })).toThrow(
      SurfboardAuthConfigError,
    );
  });

  it('throws for an unknown strategy name', () => {
    expect(() => validateAuthConfig('carrier_pigeon', {})).toThrow(SurfboardAuthConfigError);
  });
});
