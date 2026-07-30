import { describe, it, expect, vi } from 'vitest';
import { SurfboardStoreClient } from '../../../src/integrations/surfboard/store.client.js';

function createClient({ fetchImpl, config } = {}) {
  return new SurfboardStoreClient({
    fetchImpl,
    logger: { debug: vi.fn(), warn: vi.fn(), error: vi.fn() },
    config: {
      environment: 'sandbox',
      baseUrl: 'https://sandbox.example.test',
      apiKey: 'test-api-key',
      timeoutMs: 200,
      maxRetries: 0,
      ...config,
    },
  });
}

describe('SurfboardStoreClient.createStore', () => {
  it('POSTs to /stores and returns the parsed response body', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ store_id: 'sb_store_1', name: 'Main Store' }), {
        status: 201,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const client = createClient({ fetchImpl });

    const result = await client.createStore({ merchant_id: 'sb_merchant_1', name: 'Main Store' });

    expect(result).toEqual({ store_id: 'sb_store_1', name: 'Main Store' });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/stores');
    expect(init.method).toBe('POST');
  });

  it('throws a SurfboardApiError when Surfboard rejects the request', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ message: 'invalid name' }), { status: 400 }));
    const client = createClient({ fetchImpl });

    await expect(client.createStore({})).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
    });
  });
});

describe('SurfboardStoreClient.getStore', () => {
  it('GETs /stores/:storeId and returns the parsed response body', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ store_id: 'sb_store_1', name: 'Main Store', status: 'active' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const client = createClient({ fetchImpl });

    const result = await client.getStore('sb_store_1');

    expect(result).toEqual({ store_id: 'sb_store_1', name: 'Main Store', status: 'active' });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/stores/sb_store_1');
    expect(init.method).toBe('GET');
  });

  it('throws a SurfboardApiError for a non-2xx response', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ message: 'not found' }), { status: 404 }));
    const client = createClient({ fetchImpl });

    await expect(client.getStore('missing')).rejects.toMatchObject({ name: 'SurfboardApiError' });
  });
});

describe('SurfboardStoreClient.updateStore', () => {
  it('PATCHes /stores/:storeId with the wire payload', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ store_id: 'sb_store_1', name: 'New Name' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const client = createClient({ fetchImpl });

    const result = await client.updateStore('sb_store_1', { name: 'New Name' });

    expect(result).toEqual({ store_id: 'sb_store_1', name: 'New Name' });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/stores/sb_store_1');
    expect(init.method).toBe('PATCH');
    expect(JSON.parse(init.body)).toEqual({ name: 'New Name' });
  });

  it('throws a SurfboardApiError when Surfboard rejects the update', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ message: 'invalid field' }), { status: 400 }));
    const client = createClient({ fetchImpl });

    await expect(client.updateStore('sb_store_1', {})).rejects.toMatchObject({ name: 'SurfboardApiError' });
  });
});
