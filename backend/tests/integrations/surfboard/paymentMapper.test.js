import { describe, it, expect } from 'vitest';
import paymentMapper from '../../../src/integrations/surfboard/mappers/payment.mapper.js';

describe('payment.mapper', () => {
  describe('toRegisterTerminalWire / toTerminalDomain', () => {
    it('builds a PaymentPage registration request and reads back the terminalId', () => {
      expect(paymentMapper.toRegisterTerminalWire()).toEqual({ onlineTerminalMode: 'PaymentPage' });
      expect(paymentMapper.toTerminalDomain({ data: { terminalId: 'term_1' } })).toEqual({
        terminalId: 'term_1',
      });
      expect(paymentMapper.toTerminalDomain({})).toEqual({ terminalId: null });
    });
  });

  describe('toOrderWire', () => {
    it('converts cart line items into Surfboard order lines in minor currency units', () => {
      const wire = paymentMapper.toOrderWire({
        terminalId: 'term_1',
        referenceId: 'checkout-uid-1-123',
        items: [
          {
            productId: 'p1',
            name: 'Surf Wax',
            quantity: 2,
            unitPrice: 100,
            taxPercentage: 25,
            discountPercentage: 0,
          },
        ],
      });

      expect(wire['terminal$id']).toBe('term_1');
      expect(wire.referenceId).toBe('checkout-uid-1-123');
      expect(wire.orderLines).toHaveLength(1);

      const [line] = wire.orderLines;
      expect(line.id).toBe('p1');
      expect(line.name).toBe('Surf Wax');
      expect(line.quantity).toBe(2);
      // Line amounts are PER-UNIT (Surfboard multiplies by quantity itself for totalOrderAmount —
      // see toOrderWire's doc comment): unit price 100, discount 0, tax = 25% of 100 = 25,
      // unit total (tax-inclusive) = 125. regular is derived as total + campaign, so Surfboard's
      // own `total === regular + shipping - campaign` validation holds by construction.
      expect(line.amount).toMatchObject({ regular: 12500, campaign: 0, total: 12500, currency: '752' });
      expect(line.amount.tax).toEqual([{ amount: 2500, percentage: 25, type: 'VAT' }]);

      // totalOrderAmount = per-unit total × quantity (2) — see "Order Line Level Calculation".
      expect(wire.totalOrderAmount).toEqual({ regular: 25000, campaign: 0, total: 25000, currency: '752' });
    });

    it('applies per-line discount before computing tax', () => {
      const wire = paymentMapper.toOrderWire({
        terminalId: 'term_1',
        referenceId: 'checkout-uid-1-124',
        items: [
          {
            productId: 'p1',
            name: 'Wax',
            quantity: 1,
            unitPrice: 100,
            taxPercentage: 10,
            discountPercentage: 20,
          },
        ],
      });

      // subtotal = 100, discount = 20, taxable = 80, tax = 8, total (tax-inclusive) = 88.
      // regular = total + campaign = 88 + 20 = 108, so total === regular - campaign holds.
      const [line] = wire.orderLines;
      expect(line.amount).toMatchObject({ regular: 10800, campaign: 2000, total: 8800 });
      expect(line.amount.tax).toEqual([{ amount: 800, percentage: 10, type: 'VAT' }]);
      // Order-level regular === total and campaign === 0 always (unlike a line's own amount,
      // which does carry the real 2000 discount) — see toOrderWire's doc comment.
      expect(wire.totalOrderAmount).toMatchObject({ regular: 8800, campaign: 0, total: 8800 });
    });

    it('keeps line amounts per-unit and multiplies by quantity only for totalOrderAmount, with tax and discount combined', () => {
      const wire = paymentMapper.toOrderWire({
        terminalId: 'term_1',
        referenceId: 'checkout-uid-1-126',
        items: [
          {
            productId: 'p1',
            name: 'Wax 3-pack',
            quantity: 3,
            unitPrice: 100,
            taxPercentage: 7,
            discountPercentage: 10,
          },
        ],
      });

      // Per unit: discount = 10, taxable = 90, tax = 6.3, total (tax-inclusive) = 96.3.
      const [line] = wire.orderLines;
      expect(line.quantity).toBe(3);
      expect(line.amount).toMatchObject({ regular: 10630, campaign: 1000, total: 9630 });
      expect(line.amount.tax).toEqual([{ amount: 630, percentage: 7, type: 'VAT' }]);

      // Order total = per-unit total (96.3) × quantity (3) = 288.9 — NOT the per-unit total alone.
      // Order-level regular === total and campaign === 0 always (unlike a line's own amount,
      // which does carry the real 3000 discount) — see toOrderWire's doc comment.
      expect(wire.totalOrderAmount).toEqual({ regular: 28890, campaign: 0, total: 28890, currency: '752' });
    });

    // Surfboard's officially-documented redirect-back mechanism (web-guides/payment-page.md):
    // `controlFunctions.online.redirectUrl`/`failureRedirectUrl` on Create Order — see
    // payment.service.js#buildRedirectUrls, which supplies this block only when
    // config.publicBaseUrl is set (never a private/loopback/non-http(s) URL — Surfboard rejects
    // those at Create Order time, confirmed live).
    it('includes the officially-documented redirect/callback fields when redirectUrls is provided', () => {
      const wire = paymentMapper.toOrderWire({
        terminalId: 'term_1',
        referenceId: 'checkout-uid-1-200',
        items: [
          {
            productId: 'p1',
            name: 'Wax',
            quantity: 1,
            unitPrice: 100,
            taxPercentage: 0,
            discountPercentage: 0,
          },
        ],
        redirectUrls: {
          success: 'https://api.example.com/payments/redirect/success',
          failure: 'https://api.example.com/payments/redirect/failed',
          callBackUrl: 'https://api.example.com/webhooks/surfboard',
        },
      });

      expect(wire.controlFunctions.online).toEqual({
        redirectUrl: 'https://api.example.com/payments/redirect/success',
        failureRedirectUrl: 'https://api.example.com/payments/redirect/failed',
        generateShortLink: true,
      });
      expect(wire.controlFunctions.callBackUrl).toBe('https://api.example.com/webhooks/surfboard');
    });

    it('omits the redirect/callback block entirely when redirectUrls is not provided', () => {
      const wire = paymentMapper.toOrderWire({
        terminalId: 'term_1',
        referenceId: 'checkout-uid-1-201',
        items: [
          {
            productId: 'p1',
            name: 'Wax',
            quantity: 1,
            unitPrice: 100,
            taxPercentage: 0,
            discountPercentage: 0,
          },
        ],
      });

      expect(wire.controlFunctions.online).toBeUndefined();
      expect(wire.controlFunctions.callBackUrl).toBeUndefined();
    });

    it('omits callBackUrl when redirectUrls has no callBackUrl, while still setting the redirect fields', () => {
      const wire = paymentMapper.toOrderWire({
        terminalId: 'term_1',
        referenceId: 'checkout-uid-1-202',
        items: [
          {
            productId: 'p1',
            name: 'Wax',
            quantity: 1,
            unitPrice: 100,
            taxPercentage: 0,
            discountPercentage: 0,
          },
        ],
        redirectUrls: {
          success: 'https://api.example.com/payments/redirect/success',
          failure: 'https://api.example.com/payments/redirect/failed',
        },
      });

      expect(wire.controlFunctions.online).toEqual({
        redirectUrl: 'https://api.example.com/payments/redirect/success',
        failureRedirectUrl: 'https://api.example.com/payments/redirect/failed',
        generateShortLink: true,
      });
      expect(wire.controlFunctions.callBackUrl).toBeUndefined();
    });

    it('sums totals across multiple line items', () => {
      const wire = paymentMapper.toOrderWire({
        terminalId: 'term_1',
        referenceId: 'checkout-uid-1-125',
        items: [
          {
            productId: 'p1',
            name: 'A',
            quantity: 1,
            unitPrice: 100,
            taxPercentage: 0,
            discountPercentage: 0,
          },
          { productId: 'p2', name: 'B', quantity: 2, unitPrice: 50, taxPercentage: 0, discountPercentage: 0 },
        ],
      });

      expect(wire.totalOrderAmount).toEqual({ regular: 20000, campaign: 0, total: 20000, currency: '752' });
    });
  });

  describe('toOrderDomain', () => {
    it("extracts orderId and paymentUrl (Surfboard's paymentPageLink) from the envelope", () => {
      expect(
        paymentMapper.toOrderDomain({
          data: { orderId: 'order_1', paymentPageLink: 'https://pay.example/x' },
        }),
      ).toEqual({ orderId: 'order_1', paymentUrl: 'https://pay.example/x' });
      expect(paymentMapper.toOrderDomain({})).toEqual({ orderId: null, paymentUrl: null });
    });
  });

  describe('toInitiatePaymentWire', () => {
    it('builds the Initiate a Payment request body, hardcoding CARD', () => {
      expect(paymentMapper.toInitiatePaymentWire({ orderId: 'order_1', terminalId: 'term_1' })).toEqual({
        orderId: 'order_1',
        terminalId: 'term_1',
        paymentMethod: 'CARD',
      });
    });
  });

  describe('toPaymentDomain', () => {
    it('extracts paymentId and the payment-collection fields', () => {
      const domain = paymentMapper.toPaymentDomain({
        data: {
          paymentId: 'pay_1',
          paymentUrl: 'https://pay.example/x',
          qr: 'qr-data',
          qrData: 'raw',
          qrLink: 'link',
        },
      });
      expect(domain).toEqual({
        paymentId: 'pay_1',
        paymentUrl: 'https://pay.example/x',
        qr: 'qr-data',
        qrData: 'raw',
        qrLink: 'link',
      });
    });

    it('defaults every field to null when absent', () => {
      expect(paymentMapper.toPaymentDomain({})).toEqual({
        paymentId: null,
        paymentUrl: null,
        qr: null,
        qrData: null,
        qrLink: null,
      });
    });
  });

  describe('toOrderStatusDomain', () => {
    it('flattens the first payment and first transaction into the domain shape', () => {
      const domain = paymentMapper.toOrderStatusDomain({
        data: {
          orderStatus: 'PAYMENT_COMPLETED',
          payments: [
            { paymentId: 'pay_1', paymentStatus: 'PAYMENT_COMPLETED', paymentMethod: 'CARD', amount: 200 },
          ],
          transactions: [{ transactionId: 'txn_1' }],
        },
      });

      expect(domain).toEqual({
        orderStatus: 'PAYMENT_COMPLETED',
        paymentStatus: 'PAYMENT_COMPLETED',
        paymentId: 'pay_1',
        paymentMethod: 'CARD',
        amount: 200,
        failureReason: null,
        transactionId: 'txn_1',
      });
    });

    it('defaults every field to null with an empty envelope', () => {
      expect(paymentMapper.toOrderStatusDomain({})).toEqual({
        orderStatus: null,
        paymentStatus: null,
        paymentId: null,
        paymentMethod: null,
        amount: null,
        failureReason: null,
        transactionId: null,
      });
    });
  });

  describe('toCancelDomain', () => {
    it('extracts the resulting paymentStatus', () => {
      expect(paymentMapper.toCancelDomain({ data: { paymentStatus: 'PAYMENT_CANCELLED' } })).toEqual({
        paymentStatus: 'PAYMENT_CANCELLED',
      });
    });
  });
});
