import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

describe('GET /health', () => {
  it('returns a 200 with the standard success envelope', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.status).toBe('ok');
    expect(typeof response.body.data.uptimeSeconds).toBe('number');
    expect(typeof response.body.data.timestamp).toBe('string');
    expect(typeof response.body.data.version).toBe('string');
    expect(typeof response.body.data.environment).toBe('string');
  });

  it('sets an X-Request-Id response header', async () => {
    const response = await request(app).get('/health');

    expect(response.headers['x-request-id']).toBeTruthy();
  });
});
