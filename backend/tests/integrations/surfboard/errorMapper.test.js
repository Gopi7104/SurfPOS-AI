import { describe, it, expect } from 'vitest';
import { mapError, assertSurfboardSuccess } from '../../../src/integrations/surfboard/errors/errorMapper.js';
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

  it('maps a status+data failure to a SurfboardApiError carrying the httpStatus and Surfboard body', () => {
    const mapped = mapError({ status: 409, data: { status: 'ERROR', message: 'duplicate merchant' } });

    expect(mapped.name).toBe('SurfboardApiError');
    expect(mapped.httpStatus).toBe(409);
    expect(mapped.surfboardStatus).toBe('ERROR');
    expect(mapped.surfboardMessage).toBe('duplicate merchant');
    expect(mapped.body).toEqual({ status: 'ERROR', message: 'duplicate merchant' });
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

describe('assertSurfboardSuccess', () => {
  it('does nothing for a response with no status field (not the enveloped shape)', () => {
    expect(() => assertSurfboardSuccess({ status: 200, data: { id: 'sb_1' } })).not.toThrow();
  });

  it('does nothing for a null/empty body (e.g. a 204 No Content response)', () => {
    expect(() => assertSurfboardSuccess({ status: 204, data: null })).not.toThrow();
  });

  it('does nothing when the envelope reports status SUCCESS', () => {
    expect(() =>
      assertSurfboardSuccess({ status: 201, data: { status: 'SUCCESS', data: { applicationId: 'app_1' } } }),
    ).not.toThrow();
  });

  it('throws a SurfboardApiError carrying the full Surfboard error context when the HTTP-2xx envelope reports status ERROR', () => {
    const parsed = {
      status: 201,
      data: { status: 'ERROR', message: 'Invalid swedish corporate-id length.' },
    };

    let thrown;
    try {
      assertSurfboardSuccess(parsed, { requestId: 'sb_req_1' });
    } catch (err) {
      thrown = err;
    }

    expect(thrown).toBeDefined();
    expect(thrown.name).toBe('SurfboardApiError');
    expect(thrown.code).toBe(ERROR_CODES.VALIDATION_ERROR);
    expect(thrown.statusCode).toBe(400);
    expect(thrown.httpStatus).toBe(201);
    expect(thrown.surfboardStatus).toBe('ERROR');
    expect(thrown.surfboardMessage).toBe('Invalid swedish corporate-id length.');
    expect(thrown.message).toBe('Invalid swedish corporate-id length.');
    expect(thrown.body).toEqual(parsed.data);
    expect(thrown.requestId).toBe('sb_req_1');
  });
});
