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
      // subtotal = 200, discount = 0, tax = 25% of 200 = 50, total = 250
      expect(line.amount).toMatchObject({ regular: 10000, campaign: 0, total: 25000, currency: '752' });
      expect(line.amount.tax).toEqual([{ amount: 5000, percentage: 25, type: 'VAT' }]);

      expect(wire.totalOrderAmount).toEqual({ regular: 20000, campaign: 0, total: 25000, currency: '752' });
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

      // subtotal = 100, discount = 20, taxable = 80, tax = 8, total = 88
      const [line] = wire.orderLines;
      expect(line.amount).toMatchObject({ regular: 10000, campaign: 2000, total: 8800 });
      expect(line.amount.tax).toEqual([{ amount: 800, percentage: 10, type: 'VAT' }]);
      expect(wire.totalOrderAmount).toMatchObject({ regular: 10000, campaign: 2000, total: 8800 });
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
    it('extracts orderId from the envelope', () => {
      expect(paymentMapper.toOrderDomain({ data: { orderId: 'order_1' } })).toEqual({ orderId: 'order_1' });
      expect(paymentMapper.toOrderDomain({})).toEqual({ orderId: null });
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
