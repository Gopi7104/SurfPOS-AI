import { describe, it, expect, vi } from 'vitest';
import { attachAuthentication } from '../../../src/integrations/surfboard/middleware/authentication.middleware.js';

describe('attachAuthentication', () => {
  it('merges the authenticationManager headers onto the existing headers', async () => {
    const authenticationManager = {
      getAuthHeaders: vi.fn().mockResolvedValue({ Authorization: 'Bearer tok' }),
    };

    const headers = await attachAuthentication({
      headers: { Accept: 'application/json' },
      authenticationManager,
    });

    expect(headers).toEqual({ Accept: 'application/json', Authorization: 'Bearer tok' });
  });

  it('returns the headers unchanged when no authenticationManager is provided', async () => {
    const headers = await attachAuthentication({ headers: { Accept: 'application/json' } });
    expect(headers).toEqual({ Accept: 'application/json' });
  });

  it('lets auth headers override same-named headers already present', async () => {
    const authenticationManager = {
      getAuthHeaders: vi.fn().mockResolvedValue({ Authorization: 'Bearer new' }),
    };

    const headers = await attachAuthentication({
      headers: { Authorization: 'Bearer stale' },
      authenticationManager,
    });

    expect(headers.Authorization).toBe('Bearer new');
  });
});
