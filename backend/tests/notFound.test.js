import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';
import { ERROR_CODES } from '../src/constants/index.js';

describe('404 handler', () => {
  it('returns the standard error envelope for an unknown route', async () => {
    const response = await request(app).get('/this-route-does-not-exist');

    expect(response.status).toBe(404);
    expect(response.body).toEqual({
      success: false,
      error: {
        code: ERROR_CODES.NOT_FOUND,
        message: 'Route not found: GET /this-route-does-not-exist',
        details: [],
      },
    });
  });
});
