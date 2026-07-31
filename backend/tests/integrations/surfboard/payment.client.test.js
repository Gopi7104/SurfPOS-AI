import { describe, it, expect, vi } from 'vitest';
import { SurfboardPaymentClient } from '../../../src/integrations/surfboard/payment.client.js';

function createClient({ fetchImpl, config } = {}) {
  return new SurfboardPaymentClient({
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

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

describe('SurfboardPaymentClient.registerOnlineTerminal', () => {
  it('POSTs to /merchants/:merchantId/stores/:storeId/online-terminals with a MERCHANT-ID header', async () => {
    const body = {
      status: 'SUCCESS',
      data: { terminalId: '813ca2cb12ce400405' },
      message: 'Terminal registered',
    };
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse(body));
    const client = createClient({ fetchImpl });

    const result = await client.registerOnlineTerminal('sb_merchant_1', 'sb_store_1', {
      onlineTerminalMode: 'PaymentPage',
    });

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe(
      'https://sandbox.example.test/merchants/sb_merchant_1/stores/sb_store_1/online-terminals',
    );
    expect(init.method).toBe('POST');
    expect(init.headers['MERCHANT-ID']).toBe('sb_merchant_1');
    expect(JSON.parse(init.body)).toEqual({ onlineTerminalMode: 'PaymentPage' });
  });

  it('throws a SurfboardApiError when a 2xx envelope reports status ERROR', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(jsonResponse({ status: 'ERROR', message: 'Invalid onlineTerminalMode value' }));
    const client = createClient({ fetchImpl });

    await expect(
      client.registerOnlineTerminal('sb_merchant_1', 'sb_store_1', { onlineTerminalMode: 'BAD' }),
    ).rejects.toMatchObject({ name: 'SurfboardApiError' });
  });
});

describe('SurfboardPaymentClient.createOrder', () => {
  it('POSTs to /orders with a MERCHANT-ID header and returns the envelope', async () => {
    const body = {
      status: 'SUCCESS',
      data: { orderId: '83a1ba32774149710b' },
      message: 'Order created successfully',
    };
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse(body));
    const client = createClient({ fetchImpl });

    const result = await client.createOrder('sb_merchant_1', { terminal$id: 'term_1', orderLines: [] });

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/orders');
    expect(init.method).toBe('POST');
    expect(init.headers['MERCHANT-ID']).toBe('sb_merchant_1');
  });
});

describe('SurfboardPaymentClient.initiatePayment', () => {
  it('POSTs to /payments and returns paymentId/paymentUrl/qr fields', async () => {
    const body = {
      status: 'SUCCESS',
      data: {
        paymentId: '811f9bd48c6eb80c06',
        paymentUrl: 'https://pay.example/x',
        qr: 'data:image/png;...',
      },
      message: 'Payment initiated successfully',
    };
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse(body));
    const client = createClient({ fetchImpl });

    const result = await client.initiatePayment('sb_merchant_1', {
      orderId: '83a1ba32774149710b',
      terminalId: 'term_1',
      paymentMethod: 'CARD',
    });

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/payments');
    expect(init.method).toBe('POST');
  });
});

describe('SurfboardPaymentClient.getOrderStatus', () => {
  it('GETs /orders/:orderId/status with a MERCHANT-ID header', async () => {
    const body = {
      status: 'SUCCESS',
      data: { orderStatus: 'PAYMENT_COMPLETED', payments: [], paymentIds: [] },
      message: 'Fetched order status successfully',
    };
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse(body));
    const client = createClient({ fetchImpl });

    const result = await client.getOrderStatus('sb_merchant_1', '83a1ba32774149710b');

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/orders/83a1ba32774149710b/status');
    expect(init.method).toBe('GET');
    expect(init.headers['MERCHANT-ID']).toBe('sb_merchant_1');
  });
});

describe('SurfboardPaymentClient.cancelPayment', () => {
  it('DELETEs /payments/:paymentId and returns the resulting paymentStatus', async () => {
    const body = {
      status: 'SUCCESS',
      data: { paymentStatus: 'PAYMENT_CANCELLED' },
      message: 'Payment cancelled',
    };
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse(body));
    const client = createClient({ fetchImpl });

    const result = await client.cancelPayment('sb_merchant_1', '811f9bd48c6eb80c06');

    expect(result).toEqual(body);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://sandbox.example.test/payments/811f9bd48c6eb80c06');
    expect(init.method).toBe('DELETE');
  });

  it('throws a SurfboardApiError for a 403 (already completed) response', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue(
        jsonResponse(
          { status: 'ERROR', data: { paymentStatus: 'PAYMENT_COMPLETED' }, message: 'Already completed' },
          403,
        ),
      );
    const client = createClient({ fetchImpl });

    await expect(client.cancelPayment('sb_merchant_1', '811f9bd48c6eb80c06')).rejects.toMatchObject({
      name: 'SurfboardApiError',
    });
  });
});
