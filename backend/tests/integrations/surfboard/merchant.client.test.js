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
      partnerId: 'partner-1',
      timeoutMs: 200,
      maxRetries: 0,
      ...config,
    },
  });
}

describe('SurfboardMerchantClient.createMerchant', () => {
  it('POSTs to /partners/:partnerId/merchants and returns the full response envelope', async () => {
    const body = {
      status: 'SUCCESS',
      data: { applicationId: 'app_1', webKybUrl: 'https://surfkyb.com/app_1' },
    };
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify(body), { status: 201, headers: { 'Content-Type': 'application/json' } }),
      );
    const client = createClient({ fetchImpl });

    const result = await client.createMerchant({ country: 'SE' });

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/partners/partner-1/merchants');
    expect(init.method).toBe('POST');
    expect(JSON.parse(init.body)).toEqual({ country: 'SE' });
  });

  it('throws a SurfboardApiError when Surfboard rejects the request', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ status: 'ERROR', data: null, message: 'Invalid request body.' }), {
        status: 400,
      }),
    );
    const client = createClient({ fetchImpl });

    await expect(client.createMerchant({})).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
      message: 'Invalid request body.',
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

describe('SurfboardMerchantClient.getApplicationStatus', () => {
  it('GETs /partners/:partnerId/merchants/:applicationId/status', async () => {
    const body = {
      status: 'SUCCESS',
      data: {
        applicationId: 'app_1',
        applicationStatus: 'MERCHANT_CREATED',
        merchantId: 'm-1',
        storeId: 's-1',
      },
    };
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify(body), { status: 200, headers: { 'Content-Type': 'application/json' } }),
      );
    const client = createClient({ fetchImpl });

    const result = await client.getApplicationStatus('app_1');

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/partners/partner-1/merchants/app_1/status');
    expect(init.method).toBe('GET');
  });

  it('throws a SurfboardApiError for an unknown application id', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ status: 'ERROR', data: null, message: 'Invalid Application ID' }), {
        status: 400,
      }),
    );
    const client = createClient({ fetchImpl });

    await expect(client.getApplicationStatus('missing')).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
    });
  });
});

describe('SurfboardMerchantClient.getMerchant', () => {
  it('GETs /partners/:partnerId/merchants/:merchantId with a MERCHANT-ID header', async () => {
    const body = {
      status: 'SUCCESS',
      data: { merchantId: 'sb_merchant_1', merchantName: 'Blue Wave Surf Shop' },
    };
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify(body), { status: 200, headers: { 'Content-Type': 'application/json' } }),
      );
    const client = createClient({ fetchImpl });

    const result = await client.getMerchant('sb_merchant_1');

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/partners/partner-1/merchants/sb_merchant_1');
    expect(init.method).toBe('GET');
    expect(init.headers['MERCHANT-ID']).toBe('sb_merchant_1');
  });

  it('throws a SurfboardApiError for a non-2xx response', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify({ status: 'ERROR', data: null, message: 'not found' }), { status: 404 }),
      );
    const client = createClient({ fetchImpl });

    await expect(client.getMerchant('missing')).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
    });
  });
});

describe('SurfboardMerchantClient.updateMerchant', () => {
  it('PUTs /partners/:partnerId/merchants/:merchantId with the wire payload and a MERCHANT-ID header', async () => {
    const body = { status: 'SUCCESS', message: 'Successfully updated the merchant details.' };
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify(body), { status: 200, headers: { 'Content-Type': 'application/json' } }),
      );
    const client = createClient({ fetchImpl });

    const result = await client.updateMerchant('sb_merchant_1', { email: 'new@example.com' });

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/partners/partner-1/merchants/sb_merchant_1');
    expect(init.method).toBe('PUT');
    expect(init.headers['MERCHANT-ID']).toBe('sb_merchant_1');
    expect(JSON.parse(init.body)).toEqual({ email: 'new@example.com' });
  });

  it('throws a SurfboardApiError when Surfboard rejects the update', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ status: 'ERROR', data: null, message: 'invalid field' }), {
        status: 400,
      }),
    );
    const client = createClient({ fetchImpl });

    await expect(client.updateMerchant('sb_merchant_1', {})).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: 'SURFBOARD_ERROR',
    });
  });
});
