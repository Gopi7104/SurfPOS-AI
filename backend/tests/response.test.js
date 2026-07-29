import { describe, it, expect } from 'vitest';
import { sendSuccess, sendError } from '../src/utils/response.js';
import { HTTP_STATUS, ERROR_CODES } from '../src/constants/index.js';

function createMockRes() {
  return {
    statusCode: null,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };
}

describe('response envelope helpers', () => {
  it('sendSuccess wraps data in the standard success envelope', () => {
    const res = createMockRes();

    sendSuccess(res, { foo: 'bar' });

    expect(res.statusCode).toBe(HTTP_STATUS.OK);
    expect(res.body).toEqual({ success: true, data: { foo: 'bar' } });
  });

  it('sendSuccess honors a custom status code', () => {
    const res = createMockRes();

    sendSuccess(res, { id: '1' }, HTTP_STATUS.CREATED);

    expect(res.statusCode).toBe(HTTP_STATUS.CREATED);
  });

  it('sendError wraps error info in the standard error envelope', () => {
    const res = createMockRes();

    sendError(res, {
      code: ERROR_CODES.CONFLICT,
      message: 'Duplicate SKU',
      statusCode: HTTP_STATUS.CONFLICT,
    });

    expect(res.statusCode).toBe(HTTP_STATUS.CONFLICT);
    expect(res.body).toEqual({
      success: false,
      error: { code: ERROR_CODES.CONFLICT, message: 'Duplicate SKU', details: [] },
    });
  });

  it('sendError defaults to a 500 internal error when no statusCode is given', () => {
    const res = createMockRes();

    sendError(res, { message: 'Boom' });

    expect(res.statusCode).toBe(HTTP_STATUS.INTERNAL_SERVER_ERROR);
    expect(res.body.error.code).toBe(ERROR_CODES.INTERNAL_ERROR);
  });
});
