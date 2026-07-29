import { describe, it, expect } from 'vitest';
import { loadCredentials, redact } from '../../../src/integrations/surfboard/auth/credentialLoader.js';

describe('loadCredentials', () => {
  it('extracts only the known credential fields from config', () => {
    const credentials = loadCredentials({
      apiKey: 'key_123',
      apiSecret: 'secret_456',
      bearerToken: 'bearer_789',
      baseUrl: 'https://sandbox.example.test',
    });

    expect(credentials).toEqual({ apiKey: 'key_123', apiSecret: 'secret_456', bearerToken: 'bearer_789' });
  });

  it('returns undefined fields when config has no credentials', () => {
    expect(loadCredentials({})).toEqual({ apiKey: undefined, apiSecret: undefined, bearerToken: undefined });
  });
});

describe('redact', () => {
  it('masks all but the last 4 characters', () => {
    expect(redact('abcdefgh12')).toBe('******gh12');
  });

  it('fully masks a secret of 4 characters or fewer', () => {
    expect(redact('abcd')).toBe('****');
    expect(redact('ab')).toBe('****');
  });

  it('returns undefined for a missing secret', () => {
    expect(redact(undefined)).toBeUndefined();
  });
});
