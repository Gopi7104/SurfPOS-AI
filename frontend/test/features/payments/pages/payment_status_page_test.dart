import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/payments/models/checkout_item.dart';
import 'package:surfpos_ai/features/payments/models/checkout_result_model.dart';
import 'package:surfpos_ai/features/payments/models/order_status_model.dart';
import 'package:surfpos_ai/features/payments/pages/payment_status_page.dart';
import 'package:surfpos_ai/features/payments/providers/payment_providers.dart';
import 'package:surfpos_ai/features/payments/repositories/payment_repository.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_line_item.dart';
import 'package:surfpos_ai/features/receipt/providers/receipt_providers.dart';

import '../../merchant/presentation/screens/test_surface.dart';
import '../../receipt/fakes/fake_receipt_repository.dart';
import '../fakes/fake_payment_repository.dart';

const _items = [CheckoutItem(productId: 'p1', quantity: 1)];
const _receiptItems = [
  ReceiptLineItem(
      productName: 'Widget', quantity: 1, unitPrice: 199.5, lineTotal: 199.5),
];

Widget _wrap(PaymentRepository repository, {required VoidCallback onDone}) {
  return ProviderScope(
    overrides: [
      paymentRepositoryProvider.overrideWithValue(repository),
      // The real repository calls Bluetooth/share platform channels that
      // have no handler in `flutter test` — the payment flow itself is what
      // this file tests, not Receipt's printer detection.
      receiptRepositoryProvider.overrideWithValue(FakeReceiptRepository()),
    ],
    child: MaterialApp(
      home: PaymentStatusPage(
        uid: 'uid-1',
        storeId: 'store-1',
        items: _items,
        merchantName: 'Acme Surf Co',
        storeName: 'Downtown',
        receiptItems: _receiptItems,
        onDone: onDone,
      ),
    ),
  );
}

void main() {
  testWidgets(
      'approved payment navigates to the Receipt screen with the sale details',
      (tester) async {
    useTallTestSurface(tester);
    var done = false;
    await tester.pumpWidget(
      _wrap(
        FakePaymentRepository(
          createCheckout: ({storeId, required items}) async =>
              const CheckoutResultModel(
            orderId: 'order-1',
            paymentId: 'pay-1',
            amount: 199.5,
          ),
          getCheckoutStatus: (orderId) async => const OrderStatusModel(
            paymentStatus: 'PAYMENT_COMPLETED',
            paymentMethod: 'CARD',
            transactionId: 'txn-1',
          ),
          openPaymentUrl: (url) async {},
        ),
        onDone: () => done = true,
      ),
    );

    await tester.pump(); // post-frame callback fires startCheckout
    await tester.pump(); // resolve createCheckout's Future
    await tester.pump(const Duration(seconds: 2)); // first poll tick
    await tester.pump(); // resolve getCheckoutStatus's Future
    await tester.pumpAndSettle(); // ref.listen navigates to PaymentSuccessPage

    // Lands on the standalone Payment Successful page first, not Receipt
    // directly — the cashier taps through to Receipt explicitly.
    expect(find.text('Payment Approved'), findsOneWidget);
    expect(find.text('pay-1'), findsOneWidget); // Reference
    expect(find.text('txn-1'), findsOneWidget);
    expect(find.text('Acme Surf Co'), findsOneWidget);
    expect(find.text('Receipt'), findsNothing);

    await tester.tap(find.text('View Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('pay-1'), findsOneWidget); // Approval Code
    expect(find.text('order-1'), findsWidgets); // Order ID + Reference
    expect(find.text('txn-1'), findsOneWidget);
    expect(find.text('Acme Surf Co'), findsOneWidget);

    await tester.tap(find.text('New Sale'));
    expect(done, isTrue);
  });

  testWidgets(
      'declined payment shows the Surfboard failure reason and a Retry button',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        FakePaymentRepository(
          createCheckout: ({storeId, required items}) async =>
              const CheckoutResultModel(orderId: 'order-1', paymentId: 'pay-1'),
          getCheckoutStatus: (orderId) async => const OrderStatusModel(
            paymentStatus: 'PAYMENT_FAILED',
            failureReason: 'Insufficient funds',
          ),
          openPaymentUrl: (url) async {},
        ),
        onDone: () {},
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Payment Failed'), findsOneWidget);
    expect(find.text('Insufficient funds'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Back to Cart'), findsOneWidget);
  });

  testWidgets('Cancel button cancels an in-flight payment', (tester) async {
    useTallTestSurface(tester);
    String? cancelledPaymentId;
    await tester.pumpWidget(
      _wrap(
        FakePaymentRepository(
          createCheckout: ({storeId, required items}) async =>
              const CheckoutResultModel(orderId: 'order-1', paymentId: 'pay-1'),
          getCheckoutStatus: (orderId) async =>
              const OrderStatusModel(paymentStatus: 'PAYMENT_INITIATED'),
          openPaymentUrl: (url) async {},
          cancelPayment: (paymentId) async => cancelledPaymentId = paymentId,
        ),
        onDone: () {},
      ),
    );

    await tester.pump();
    await tester.pump();

    // Appears twice by design — once as the progress-step label, once as the page title.
    expect(find.text('Waiting For Customer'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(cancelledPaymentId, 'pay-1');
    expect(find.text('Payment Cancelled'), findsOneWidget);
  });
}
