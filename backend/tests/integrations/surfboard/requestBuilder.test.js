import { describe, it, expect } from 'vitest';
import { buildUrl, buildRequest } from '../../../src/integrations/surfboard/utils/requestBuilder.js';

describe('buildUrl', () => {
  it('joins baseUrl and path', () => {
    const url = buildUrl('https://api.example.test', '/merchants/1');
    expect(url.toString()).toBe('https://api.example.test/merchants/1');
  });

  it('appends query params, skipping undefined/null values', () => {
    const url = buildUrl('https://api.example.test', '/products', {
      limit: 20,
      cursor: undefined,
      active: true,
    });
    expect(url.toString()).toBe('https://api.example.test/products?limit=20&active=true');
  });
});

describe('buildRequest', () => {
  it('builds a GET request with default headers and no body', () => {
    const { url, init } = buildRequest({
      baseUrl: 'https://api.example.test',
      method: 'GET',
      path: '/health',
    });

    expect(url).toBe('https://api.example.test/health');
    expect(init.method).toBe('GET');
    expect(init.headers['Content-Type']).toBe('application/json');
    expect(init.body).toBeUndefined();
  });

  it('serializes a body to JSON for a POST request', () => {
    const { init } = buildRequest({
      baseUrl: 'https://api.example.test',
      method: 'POST',
      path: '/merchants',
      body: { businessName: 'Blue Wave' },
    });

    expect(init.body).toBe(JSON.stringify({ businessName: 'Blue Wave' }));
  });

  it('merges custom headers over the defaults', () => {
    const { init } = buildRequest({
      baseUrl: 'https://api.example.test',
      method: 'GET',
      path: '/merchants',
      headers: { Authorization: 'Bearer abc' },
    });

    expect(init.headers.Authorization).toBe('Bearer abc');
    expect(init.headers.Accept).toBe('application/json');
  });
});
