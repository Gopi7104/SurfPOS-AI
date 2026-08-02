import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';

describe('GET /payments/redirect/success', () => {
  it('redirects to the surfpos success deep link, preserving orderId', async () => {
    const response = await request(app).get('/payments/redirect/success').query({ orderId: 'order_123' });

    expect(response.status).toBe(302);
    expect(response.headers.location).toBe('surfpos://payment/success?orderId=order_123');
  });

  it('redirects without a query string when orderId is absent', async () => {
    const response = await request(app).get('/payments/redirect/success');

    expect(response.status).toBe(302);
    expect(response.headers.location).toBe('surfpos://payment/success');
  });
});

describe('GET /payments/redirect/failed', () => {
  it('redirects to the surfpos failed deep link, preserving orderId', async () => {
    const response = await request(app).get('/payments/redirect/failed').query({ orderId: 'order_456' });

    expect(response.status).toBe(302);
    expect(response.headers.location).toBe('surfpos://payment/failed?orderId=order_456');
  });
});
