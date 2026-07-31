import { describe, it, expect, vi } from 'vitest';
import { createPaymentService } from '../../../src/modules/payments/payment.service.js';

function createFakePaymentClient(overrides = {}) {
  return {
    registerOnlineTerminal: vi.fn().mockResolvedValue({ data: { terminalId: 'term_1' } }),
    createOrder: vi.fn().mockResolvedValue({ data: { orderId: 'order_1' } }),
    initiatePayment: vi
      .fn()
      .mockResolvedValue({ data: { paymentId: 'pay_1', paymentUrl: 'https://pay.example/x' } }),
    getOrderStatus: vi.fn().mockResolvedValue({ data: { orderStatus: 'PENDING', payments: [] } }),
    cancelPayment: vi.fn().mockResolvedValue({ data: { paymentStatus: 'PAYMENT_CANCELLED' } }),
    ...overrides,
  };
}

function createFakePaymentRepository(overrides = {}) {
  return {
    getTerminalId: vi.fn().mockResolvedValue(null),
    setTerminalId: vi.fn().mockResolvedValue(undefined),
    ...overrides,
  };
}

function createFakeMerchantService(overrides = {}) {
  return { getMerchantId: vi.fn().mockResolvedValue('sb_merchant_1'), ...overrides };
}

function createFakeStoreService(overrides = {}) {
  return {
    verifyStoreOwnership: vi.fn().mockResolvedValue(undefined),
    getPrimaryStoreId: vi.fn().mockResolvedValue('sb_store_1'),
    ...overrides,
  };
}

function createFakeLogger() {
  return { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

// billingService is the only thing allowed to resolve a cart's real price/tax/discount (see
// modules/billing/billing.service.js) — payment.service.js never sees a client-submitted price,
// so every test here fakes it with the already-resolved line items it would have returned.
function createFakeBillingService(overrides = {}) {
  return {
    resolveCheckoutItems: vi.fn().mockResolvedValue({
      items: [
        {
          productId: 'p1',
          name: 'Wax',
          quantity: 1,
          unitPrice: 100,
          taxPercentage: 25,
          discountPercentage: 0,
        },
      ],
      subtotal: 100,
      discountTotal: 0,
      taxTotal: 25,
      grandTotal: 125,
    }),
    ...overrides,
  };
}

// Uses the real mapper — the wire/domain shape is exactly what paymentMapper.test.js verifies in
// isolation, and re-verifying it here would be redundant; these tests focus on orchestration.
const realMapper = await import('../../../src/integrations/surfboard/mappers/payment.mapper.js').then(
  (m) => m.default,
);

// The client only ever sends {productId, quantity} — see validators/payment.validation.js.
const ITEMS = [{ productId: 'p1', quantity: 1 }];

describe('payment.service', () => {
  describe('createCheckout', () => {
    it('registers a terminal on first use, creates an order, and initiates payment', async () => {
      const paymentClient = createFakePaymentClient();
      const paymentRepository = createFakePaymentRepository();
      const merchantService = createFakeMerchantService();
      const storeService = createFakeStoreService();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository,
        merchantService,
        storeService,
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      const checkout = await service.createCheckout('uid_1', { items: ITEMS });

      expect(merchantService.getMerchantId).toHaveBeenCalledWith('uid_1');
      expect(storeService.getPrimaryStoreId).toHaveBeenCalledWith('uid_1');
      expect(paymentClient.registerOnlineTerminal).toHaveBeenCalledWith('sb_merchant_1', 'sb_store_1', {
        onlineTerminalMode: 'PaymentPage',
      });
      expect(paymentRepository.setTerminalId).toHaveBeenCalledWith('sb_store_1', 'term_1');
      expect(paymentClient.createOrder).toHaveBeenCalledWith(
        'sb_merchant_1',
        expect.objectContaining({ terminal$id: 'term_1' }),
      );
      expect(paymentClient.initiatePayment).toHaveBeenCalledWith('sb_merchant_1', {
        orderId: 'order_1',
        terminalId: 'term_1',
        paymentMethod: 'CARD',
      });
      expect(checkout).toMatchObject({
        orderId: 'order_1',
        storeId: 'sb_store_1',
        paymentId: 'pay_1',
        paymentUrl: 'https://pay.example/x',
        amount: 125, // 100 * 1.25 (25% VAT, no discount)
      });
    });

    it('reuses a cached terminalId instead of registering a new one', async () => {
      const paymentClient = createFakePaymentClient();
      const paymentRepository = createFakePaymentRepository({
        getTerminalId: vi.fn().mockResolvedValue('term_cached'),
      });
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository,
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      await service.createCheckout('uid_1', { items: ITEMS });

      expect(paymentClient.registerOnlineTerminal).not.toHaveBeenCalled();
      expect(paymentClient.createOrder).toHaveBeenCalledWith(
        'sb_merchant_1',
        expect.objectContaining({ terminal$id: 'term_cached' }),
      );
    });

    it('verifies ownership when an explicit storeId is given, instead of resolving the primary store', async () => {
      const storeService = createFakeStoreService();
      const service = createPaymentService({
        paymentClient: createFakePaymentClient(),
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService,
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      await service.createCheckout('uid_1', { storeId: 'sb_store_9', items: ITEMS });

      expect(storeService.verifyStoreOwnership).toHaveBeenCalledWith('uid_1', 'sb_store_9');
      expect(storeService.getPrimaryStoreId).not.toHaveBeenCalled();
    });

    it('throws NotFoundError when the caller has no store at all', async () => {
      const service = createPaymentService({
        paymentClient: createFakePaymentClient(),
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService({ getPrimaryStoreId: vi.fn().mockResolvedValue(null) }),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      await expect(service.createCheckout('uid_1', { items: ITEMS })).rejects.toMatchObject({
        name: 'NotFoundError',
        code: 'NOT_FOUND',
      });
    });

    it('propagates a SurfboardApiError from order creation untouched', async () => {
      const surfboardError = Object.assign(new Error('failed'), {
        name: 'SurfboardApiError',
        code: 'SURFBOARD_ERROR',
      });
      const paymentClient = createFakePaymentClient({
        createOrder: vi.fn().mockRejectedValue(surfboardError),
      });
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      await expect(service.createCheckout('uid_1', { items: ITEMS })).rejects.toBe(surfboardError);
      expect(paymentClient.initiatePayment).not.toHaveBeenCalled();
    });
  });

  describe('retryPayment', () => {
    it('re-initiates payment against the same orderId without creating a new order', async () => {
      const paymentClient = createFakePaymentClient({ getTerminalId: undefined });
      const paymentRepository = createFakePaymentRepository({
        getTerminalId: vi.fn().mockResolvedValue('term_1'),
      });
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository,
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      const result = await service.retryPayment('uid_1', 'order_1', 'sb_store_1');

      expect(paymentClient.createOrder).not.toHaveBeenCalled();
      expect(paymentClient.initiatePayment).toHaveBeenCalledWith('sb_merchant_1', {
        orderId: 'order_1',
        terminalId: 'term_1',
        paymentMethod: 'CARD',
      });
      expect(result).toMatchObject({ orderId: 'order_1', paymentId: 'pay_1' });
    });
  });

  describe('getCheckoutStatus', () => {
    it('resolves the merchantId and returns the mapped order status', async () => {
      const paymentClient = createFakePaymentClient({
        getOrderStatus: vi.fn().mockResolvedValue({
          data: {
            orderStatus: 'PAYMENT_COMPLETED',
            payments: [
              { paymentId: 'pay_1', paymentStatus: 'PAYMENT_COMPLETED', paymentMethod: 'CARD', amount: 125 },
            ],
            transactions: [{ transactionId: 'txn_1' }],
          },
        }),
      });
      const merchantService = createFakeMerchantService();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService,
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      const status = await service.getCheckoutStatus('uid_1', 'order_1');

      expect(merchantService.getMerchantId).toHaveBeenCalledWith('uid_1');
      expect(paymentClient.getOrderStatus).toHaveBeenCalledWith('sb_merchant_1', 'order_1');
      expect(status).toMatchObject({
        orderStatus: 'PAYMENT_COMPLETED',
        paymentStatus: 'PAYMENT_COMPLETED',
        transactionId: 'txn_1',
      });
    });
  });

  describe('cancelCheckout', () => {
    it('resolves the merchantId and cancels the payment', async () => {
      const paymentClient = createFakePaymentClient();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      const result = await service.cancelCheckout('uid_1', 'pay_1');

      expect(paymentClient.cancelPayment).toHaveBeenCalledWith('sb_merchant_1', 'pay_1');
      expect(result).toEqual({ paymentStatus: 'PAYMENT_CANCELLED' });
    });

    it('propagates a SurfboardApiError (e.g. already-completed) untouched', async () => {
      const surfboardError = Object.assign(new Error('already completed'), {
        name: 'SurfboardApiError',
        code: 'SURFBOARD_ERROR',
      });
      const paymentClient = createFakePaymentClient({
        cancelPayment: vi.fn().mockRejectedValue(surfboardError),
      });
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      await expect(service.cancelCheckout('uid_1', 'pay_1')).rejects.toBe(surfboardError);
    });
  });
});
