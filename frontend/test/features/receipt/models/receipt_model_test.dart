import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/payments/models/payment_phase.dart';
import 'package:surfpos_ai/features/payments/models/payment_state.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_line_item.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_model.dart';

void main() {
  group('ReceiptModel.fromPayment', () {
    test('carries every identifier/total field from the completed payment', () {
      const state = PaymentState(
        phase: PaymentPhase.paymentSuccessful,
        orderId: 'order-1',
        paymentId: 'pay-1',
        transactionId: 'txn-1',
        amount: 22,
        subtotal: 20,
        discountTotal: 0,
        taxTotal: 2,
        paymentMethod: 'CARD',
      );
      const items = [
        ReceiptLineItem(
            productName: 'Widget', quantity: 2, unitPrice: 10, lineTotal: 20),
      ];
      final completedAt = DateTime(2026, 1, 1, 12, 30);

      final receipt = ReceiptModel.fromPayment(
        state: state,
        merchantName: 'Acme Surf Co',
        storeName: 'Downtown',
        items: items,
        completedAt: completedAt,
      );

      expect(receipt.merchantName, 'Acme Surf Co');
      expect(receipt.storeName, 'Downtown');
      expect(receipt.orderId, 'order-1');
      expect(receipt.paymentId, 'pay-1');
      expect(receipt.transactionId, 'txn-1');
      expect(receipt.completedAt, completedAt);
      expect(receipt.items, items);
      expect(receipt.subtotal, 20);
      expect(receipt.discountTotal, 0);
      expect(receipt.taxTotal, 2);
      expect(receipt.total, 22);
      expect(receipt.paymentMethod, 'CARD');
      expect(receipt.paymentStatus, 'Successful');
    });

    test('falls back to sensible defaults when optional fields are missing',
        () {
      const state = PaymentState(phase: PaymentPhase.paymentSuccessful);

      final receipt = ReceiptModel.fromPayment(
        state: state,
        merchantName: 'Acme Surf Co',
        storeName: 'Downtown',
        items: const [],
        completedAt: DateTime(2026, 1, 1),
      );

      expect(receipt.orderId, '—');
      expect(receipt.paymentId, isNull);
      expect(receipt.transactionId, isNull);
      expect(receipt.subtotal, 0);
      expect(receipt.discountTotal, 0);
      expect(receipt.taxTotal, 0);
      expect(receipt.total, 0);
      expect(receipt.paymentMethod, 'Card');
      expect(receipt.customerName, isNull);
      expect(receipt.customerPhone, isNull);
    });

    test('carries the optional customer details through when provided', () {
      const state = PaymentState(phase: PaymentPhase.paymentSuccessful);

      final receipt = ReceiptModel.fromPayment(
        state: state,
        merchantName: 'Acme Surf Co',
        storeName: 'Downtown',
        items: const [],
        completedAt: DateTime(2026, 1, 1),
        customerName: 'Alex',
        customerPhone: '+46701234567',
      );

      expect(receipt.customerName, 'Alex');
      expect(receipt.customerPhone, '+46701234567');
    });
  });
}
