import { describe, it, expect } from 'vitest';
import { mapError } from '../../../src/integrations/surfboard/errors/errorMapper.js';
import { ERROR_CODES } from '../../../src/constants/index.js';

describe('mapError', () => {
  it('passes an already-mapped SurfboardApiError through unchanged (no double-wrapping)', () => {
    const first = mapError(new Error('boom'));

    const second = mapError(first);

    expect(second).toBe(first);
  });

  it('maps an AbortError to a timeout SurfboardApiError', () => {
    const abortError = Object.assign(new Error('aborted'), { name: 'AbortError' });

    const mapped = mapError(abortError, { requestId: 'sb_req_1' });

    expect(mapped.name).toBe('SurfboardApiError');
    expect(mapped.code).toBe(ERROR_CODES.SURFBOARD_ERROR);
    expect(mapped.message).toBe('Surfboard request timed out');
    expect(mapped.requestId).toBe('sb_req_1');
  });

  it('maps a status+data failure to a SurfboardApiError carrying the surfboardStatus', () => {
    const mapped = mapError({ status: 409, data: { message: 'duplicate merchant' } });

    expect(mapped.name).toBe('SurfboardApiError');
    expect(mapped.surfboardStatus).toBe(409);
    expect(mapped.message).toBe('duplicate merchant');
  });

  it('falls back to a generic message for an unrecognized error shape', () => {
    const cause = new Error('network exploded');

    const mapped = mapError(cause);

    expect(mapped.name).toBe('SurfboardApiError');
    expect(mapped.message).toBe('Surfboard request failed');
    expect(mapped.cause).toBe(cause);
  });
});
