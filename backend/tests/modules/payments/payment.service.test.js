import { describe, it, expect, vi } from 'vitest';
import { createPaymentService } from '../../../src/modules/payments/payment.service.js';

function createFakePaymentClient(overrides = {}) {
  return {
    registerOnlineTerminal: vi.fn().mockResolvedValue({ data: { terminalId: 'term_1' } }),
    createOrder: vi
      .fn()
      .mockResolvedValue({ data: { orderId: 'order_1', paymentPageLink: 'https://pay.example/x' } }),
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
    getPaymentUrl: vi.fn().mockResolvedValue('https://pay.example/x'),
    setPaymentUrl: vi.fn().mockResolvedValue(undefined),
    getCheckoutItems: vi.fn().mockResolvedValue(ITEMS),
    setCheckoutItems: vi.fn().mockResolvedValue(undefined),
    // Defaults to "no webhook has arrived yet" so existing tests keep exercising the Fetch Order
    // Status poll path unchanged; getCheckoutStatus's webhook-cache-first tests override this.
    getWebhookStatus: vi.fn().mockResolvedValue(null),
    setWebhookStatus: vi.fn().mockResolvedValue(undefined),
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
    // Already converted to an online store by default — see ensureStoreOnlineInfo(). Tests for
    // the "not yet online" path override this explicitly.
    getStore: vi
      .fn()
      .mockResolvedValue({ id: 'sb_store_1', onlineInfo: { merchantWebshopURL: 'https://example.com' } }),
    updateStore: vi.fn().mockResolvedValue({ id: 'sb_store_1' }),
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
    it('registers a terminal on first use, creates an order, and returns its hosted payment link', async () => {
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
      // Never called — confirmed live to be both unnecessary and broken (PS_0025) for a
      // PaymentPage-mode order, see payment.mapper.js#toOrderWire's doc comment.
      expect(paymentClient.initiatePayment).not.toHaveBeenCalled();
      expect(paymentRepository.setPaymentUrl).toHaveBeenCalledWith('order_1', 'https://pay.example/x');
      expect(paymentRepository.setCheckoutItems).toHaveBeenCalledWith('order_1', ITEMS);
      expect(checkout).toMatchObject({
        orderId: 'order_1',
        storeId: 'sb_store_1',
        paymentId: null,
        paymentUrl: 'https://pay.example/x',
        amount: 125, // 100 * 1.25 (25% VAT, no discount)
      });
    });

    it('omits the redirect/callback block when PUBLIC_BASE_URL is not configured (buildRedirectUrls() returns null)', async () => {
      const paymentClient = createFakePaymentClient();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
        config: { publicBaseUrl: undefined },
      });

      await service.createCheckout('uid_1', { items: ITEMS });

      const wire = paymentClient.createOrder.mock.calls[0][1];
      expect(wire.controlFunctions.online).toBeUndefined();
      expect(wire.controlFunctions.callBackUrl).toBeUndefined();
    });

    it('includes the officially-documented redirectUrl/failureRedirectUrl/callBackUrl when PUBLIC_BASE_URL is configured', async () => {
      const paymentClient = createFakePaymentClient();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
        config: { publicBaseUrl: 'https://api.example.com/' },
      });

      await service.createCheckout('uid_1', { items: ITEMS });

      const wire = paymentClient.createOrder.mock.calls[0][1];
      expect(wire.controlFunctions.online).toEqual({
        redirectUrl: 'https://api.example.com/payments/redirect/success',
        failureRedirectUrl: 'https://api.example.com/payments/redirect/failed',
        generateShortLink: true,
      });
      expect(wire.controlFunctions.callBackUrl).toBe('https://api.example.com/webhooks/surfboard');
    });

    it('converts the store to an online store (sets onlineInfo) before registering a terminal, when missing', async () => {
      const paymentClient = createFakePaymentClient();
      const storeService = createFakeStoreService({
        getStore: vi.fn().mockResolvedValue({ id: 'sb_store_1', onlineInfo: null }),
      });
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository(),
        merchantService: createFakeMerchantService(),
        storeService,
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      await service.createCheckout('uid_1', { items: ITEMS });

      expect(storeService.getStore).toHaveBeenCalledWith('uid_1', 'sb_store_1');
      expect(storeService.updateStore).toHaveBeenCalledWith('uid_1', 'sb_store_1', {
        onlineInfo: expect.objectContaining({
          merchantWebshopURL: expect.any(String),
          termsAndConditionsURL: expect.any(String),
          privacyPolicyURL: expect.any(String),
        }),
      });
      // Must happen before terminal registration — Surfboard rejects it otherwise (TM_0029).
      const updateOrder = storeService.updateStore.mock.invocationCallOrder[0];
      const registerOrder = paymentClient.registerOnlineTerminal.mock.invocationCallOrder[0];
      expect(updateOrder).toBeLessThan(registerOrder);
    });

    it('skips updateStore when the store already has onlineInfo set', async () => {
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

      await service.createCheckout('uid_1', { items: ITEMS });

      expect(storeService.getStore).toHaveBeenCalledWith('uid_1', 'sb_store_1');
      expect(storeService.updateStore).not.toHaveBeenCalled();
    });

    it('reuses a cached terminalId instead of registering a new one', async () => {
      const paymentClient = createFakePaymentClient();
      const paymentRepository = createFakePaymentRepository({
        getTerminalId: vi.fn().mockResolvedValue('term_cached'),
      });
      const storeService = createFakeStoreService();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository,
        merchantService: createFakeMerchantService(),
        storeService,
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      await service.createCheckout('uid_1', { items: ITEMS });

      // A cached terminalId means we never need to check/set the store's online status again.
      expect(storeService.getStore).not.toHaveBeenCalled();

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
    });
  });

  describe('retryPayment', () => {
    it("creates a brand-new order with its own fresh payment link, instead of reopening the previous order's link", async () => {
      // Surfboard's hosted Payment Page is a one-shot session — once the previous attempt on
      // order_1 concluded (failed/cancelled/expired), reopening its cached link would show
      // Surfboard's own "Invalid or Expired Link" page. Retry must mint a NEW order/link instead.
      const paymentClient = createFakePaymentClient({
        getOrderStatus: vi.fn().mockResolvedValue({ data: { orderStatus: 'PENDING', payments: [] } }),
        createOrder: vi
          .fn()
          .mockResolvedValue({ data: { orderId: 'order_2', paymentPageLink: 'https://pay.example/retry' } }),
      });
      const paymentRepository = createFakePaymentRepository({
        getCheckoutItems: vi.fn().mockResolvedValue(ITEMS),
      });
      const storeService = createFakeStoreService();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository,
        merchantService: createFakeMerchantService(),
        storeService,
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      const result = await service.retryPayment('uid_1', 'order_1', 'sb_store_1');

      expect(storeService.verifyStoreOwnership).toHaveBeenCalledWith('uid_1', 'sb_store_1');
      expect(paymentRepository.getCheckoutItems).toHaveBeenCalledWith('order_1');
      expect(paymentClient.createOrder).toHaveBeenCalledWith(
        'sb_merchant_1',
        expect.objectContaining({ terminal$id: expect.any(String) }),
      );
      expect(paymentClient.initiatePayment).not.toHaveBeenCalled();
      // order_1's own referenceId must never reappear on the retry's request — it's a genuinely
      // new order, not a mutation of the old one.
      const retryReferenceId = paymentClient.createOrder.mock.calls[0][1].referenceId;
      expect(retryReferenceId).toMatch(/^checkout-retry-/);
      expect(paymentRepository.setCheckoutItems).toHaveBeenCalledWith('order_2', ITEMS);
      expect(result).toMatchObject({
        orderId: 'order_2',
        paymentUrl: 'https://pay.example/retry',
        paymentId: null,
      });
    });

    it('refuses to retry an order that has already completed', async () => {
      const paymentClient = createFakePaymentClient({
        getOrderStatus: vi.fn().mockResolvedValue({
          data: { orderStatus: 'PAYMENT_COMPLETED', payments: [{ paymentStatus: 'PAYMENT_COMPLETED' }] },
        }),
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

      await expect(service.retryPayment('uid_1', 'order_1', 'sb_store_1')).rejects.toMatchObject({
        name: 'NotFoundError',
      });
      expect(paymentClient.createOrder).not.toHaveBeenCalled();
    });

    it('refuses to retry an order that has already partially completed', async () => {
      const paymentClient = createFakePaymentClient({
        getOrderStatus: vi.fn().mockResolvedValue({
          data: {
            orderStatus: 'PARTIAL_PAYMENT_COMPLETED',
            payments: [{ paymentStatus: 'PAYMENT_COMPLETED' }],
          },
        }),
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

      await expect(service.retryPayment('uid_1', 'order_1', 'sb_store_1')).rejects.toMatchObject({
        name: 'NotFoundError',
      });
      expect(paymentClient.createOrder).not.toHaveBeenCalled();
    });

    it("refuses to retry when the original order's items were never cached (context lost)", async () => {
      const paymentClient = createFakePaymentClient({
        getOrderStatus: vi.fn().mockResolvedValue({ data: { orderStatus: 'PENDING', payments: [] } }),
      });
      const paymentRepository = createFakePaymentRepository({
        getCheckoutItems: vi.fn().mockResolvedValue(null),
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

      await expect(service.retryPayment('uid_1', 'order_1', 'sb_store_1')).rejects.toMatchObject({
        name: 'NotFoundError',
      });
      expect(paymentClient.createOrder).not.toHaveBeenCalled();
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

    it('returns a cached webhook status and never calls Fetch Order Status when one exists', async () => {
      // Confirmed live: Fetch Order Status can lag a real completed payment by minutes on
      // Surfboard's sandbox — a cached webhook result must win outright, not just be preferred.
      const cachedStatus = {
        orderId: 'order_1',
        orderStatus: 'PAYMENT_COMPLETED',
        paymentStatus: 'PAYMENT_COMPLETED',
        paymentId: 'pay_1',
        paymentMethod: 'CARD',
        amount: '200',
        failureReason: null,
        transactionId: 'txn_1',
      };
      const paymentClient = createFakePaymentClient();
      const service = createPaymentService({
        paymentClient,
        mapper: realMapper,
        paymentRepository: createFakePaymentRepository({
          getWebhookStatus: vi.fn().mockResolvedValue(cachedStatus),
        }),
        merchantService: createFakeMerchantService(),
        storeService: createFakeStoreService(),
        billingService: createFakeBillingService(),
        logger: createFakeLogger(),
      });

      const status = await service.getCheckoutStatus('uid_1', 'order_1');

      expect(status).toEqual(cachedStatus);
      expect(paymentClient.getOrderStatus).not.toHaveBeenCalled();
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
