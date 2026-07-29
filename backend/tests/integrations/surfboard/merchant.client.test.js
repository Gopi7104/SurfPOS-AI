import { describe, it, expect, vi } from 'vitest';
import { SurfboardMerchantClient } from '../../../src/integrations/surfboard/merchant.client.js';

function createClient({ fetchImpl, config } = {}) {
  return new SurfboardMerchantClient({
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

describe('SurfboardMerchantClient.createMerchant', () => {
  it('POSTs to /merchants and returns the parsed response body', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ application_id: 'app_1', status: 'pending_verification' }), {
        status: 201,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const client = createClient({ fetchImpl });

    const result = await client.createMerchant({ business_name: 'Blue Wave Surf Shop' });

    expect(result).toEqual({ application_id: 'app_1', status: 'pending_verification' });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/merchants');
    expect(init.method).toBe('POST');
    expect(JSON.parse(init.body)).toEqual({ business_name: 'Blue Wave Surf Shop' });
  });

  it('throws a SurfboardApiError when Surfboard rejects the request', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ message: 'invalid business type' }), { status: 400 }));
    const client = createClient({ fetchImpl });

    await expect(client.createMerchant({})).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
      message: 'invalid business type',
    });
  });

  it('maps a timeout into a SurfboardApiError', async () => {
    const fetchImpl = vi.fn(
      (url, init) =>
        new Promise((_resolve, reject) => {
          init.signal.addEventListener('abort', () => {
            const error = new Error('aborted');
            error.name = 'AbortError';
            reject(error);
          });
        }),
    );
    const client = createClient({ fetchImpl, config: { timeoutMs: 20, maxRetries: 0 } });

    await expect(client.createMerchant({})).rejects.toMatchObject({ code: 'SURFBOARD_ERROR' });
  });
});

describe('SurfboardMerchantClient.getMerchant', () => {
  it('GETs /merchants/:merchantId and returns the parsed response body', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ merchant_id: 'sb_merchant_1', status: 'active' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const client = createClient({ fetchImpl });

    const result = await client.getMerchant('sb_merchant_1');

    expect(result).toEqual({ merchant_id: 'sb_merchant_1', status: 'active' });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/merchants/sb_merchant_1');
    expect(init.method).toBe('GET');
  });

  it('throws a SurfboardApiError for a non-2xx response', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ message: 'not found' }), { status: 404 }));
    const client = createClient({ fetchImpl });

    await expect(client.getMerchant('missing')).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
    });
  });
});

describe('SurfboardMerchantClient.updateMerchant', () => {
  it('PATCHes /merchants/:merchantId with the wire payload', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({ merchant_id: 'sb_merchant_1', business_name: 'New Name', status: 'active' }),
        {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        },
      ),
    );
    const client = createClient({ fetchImpl });

    const result = await client.updateMerchant('sb_merchant_1', { business_name: 'New Name' });

    expect(result).toEqual({ merchant_id: 'sb_merchant_1', business_name: 'New Name', status: 'active' });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/merchants/sb_merchant_1');
    expect(init.method).toBe('PATCH');
    expect(JSON.parse(init.body)).toEqual({ business_name: 'New Name' });
  });

  it('throws a SurfboardApiError when Surfboard rejects the update', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ message: 'invalid field' }), { status: 400 }));
    const client = createClient({ fetchImpl });

    await expect(client.updateMerchant('sb_merchant_1', {})).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
    });
  });
});
