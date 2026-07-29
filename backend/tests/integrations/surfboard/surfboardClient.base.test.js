import { describe, it, expect, vi } from 'vitest';
import SurfboardBaseClient from '../../../src/integrations/surfboard/client/surfboardClient.base.js';
import AuthenticationManager from '../../../src/integrations/surfboard/auth/authenticationManager.js';
import { ERROR_CODES } from '../../../src/constants/index.js';

function createClient({ fetchImpl, config } = {}) {
  return new SurfboardBaseClient({
    fetchImpl,
    logger: { debug: vi.fn(), warn: vi.fn(), error: vi.fn() },
    config: {
      environment: 'sandbox',
      baseUrl: 'https://sandbox.example.test',
      apiKey: 'test-api-key',
      timeoutMs: 200,
      maxRetries: 1,
      ...config,
    },
  });
}

describe('SurfboardBaseClient', () => {
  it('returns parsed data on a successful response', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ id: 'sb_merchant_1' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const client = createClient({ fetchImpl });

    const result = await client.request({ method: 'GET', path: '/merchants/1' });

    expect(result.status).toBe(200);
    expect(result.data).toEqual({ id: 'sb_merchant_1' });
  });

  it('attaches an Authorization header and a generated X-Request-Id', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    const client = createClient({ fetchImpl });

    await client.request({ method: 'GET', path: '/ping' });

    const [, init] = fetchImpl.mock.calls[0];
    expect(init.headers.Authorization).toBe('Bearer test-api-key');
    expect(init.headers['X-Request-Id']).toMatch(/^sb_req_/);
  });

  it('builds the request URL from baseUrl + path + query', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    const client = createClient({ fetchImpl });

    await client.request({ method: 'GET', path: '/products', query: { limit: 20 } });

    const [url] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/products?limit=20');
  });

  it('throws a SurfboardApiError for a non-2xx response, without retrying a non-retryable status', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ message: 'bad input' }), { status: 400 }));
    const client = createClient({ fetchImpl });

    await expect(client.request({ method: 'POST', path: '/merchants' })).rejects.toMatchObject({
      name: 'SurfboardApiError',
      code: ERROR_CODES.SURFBOARD_ERROR,
    });
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it('retries a retryable status code and succeeds', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(new Response(null, { status: 503 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ ok: true }), { status: 200 }));
    const client = createClient({ fetchImpl, config: { maxRetries: 1 } });

    const result = await client.request({ method: 'GET', path: '/flaky' });

    expect(fetchImpl).toHaveBeenCalledTimes(2);
    expect(result.data).toEqual({ ok: true });
  });

  it('uses a configured bearer strategy instead of the default api_key strategy', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    const client = createClient({
      fetchImpl,
      config: { authStrategy: 'bearer', bearerToken: 'sess_tok' },
    });

    await client.request({ method: 'GET', path: '/ping' });

    const [, init] = fetchImpl.mock.calls[0];
    expect(init.headers.Authorization).toBe('Bearer sess_tok');
  });

  it('accepts an injected AuthenticationManager, bypassing config-based strategy selection', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    const authenticationManager = new AuthenticationManager({
      config: { authStrategy: 'bearer', bearerToken: 'injected_tok' },
    });
    const client = new SurfboardBaseClient({
      fetchImpl,
      logger: { debug: vi.fn(), warn: vi.fn(), error: vi.fn() },
      config: { baseUrl: 'https://sandbox.example.test', timeoutMs: 200, maxRetries: 1 },
      authenticationManager,
    });

    await client.request({ method: 'GET', path: '/ping' });

    const [, init] = fetchImpl.mock.calls[0];
    expect(init.headers.Authorization).toBe('Bearer injected_tok');
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

    await expect(client.request({ method: 'GET', path: '/slow' })).rejects.toMatchObject({
      code: 'SURFBOARD_ERROR',
    });
  });
});
