import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/payments/models/checkout_item.dart';
import 'package:surfpos_ai/features/payments/models/checkout_result_model.dart';
import 'package:surfpos_ai/features/payments/models/order_status_model.dart';
import 'package:surfpos_ai/features/payments/models/payment_phase.dart';
import 'package:surfpos_ai/features/payments/providers/payment_providers.dart';
import 'package:surfpos_ai/features/payments/repositories/payment_repository.dart';

import '../fakes/fake_payment_repository.dart';

const _uidA = 'uid-a';
const _uidB = 'uid-b';
const _items = [CheckoutItem(productId: 'p1', quantity: 2)];

ProviderContainer _makeContainer(PaymentRepository repository) {
  return ProviderContainer(
      overrides: [paymentRepositoryProvider.overrideWithValue(repository)]);
}

void main() {
  group('PaymentController', () {
    test('build() starts in the creatingPayment phase with no order yet', () {
      final container = _makeContainer(FakePaymentRepository());
      addTearDown(container.dispose);
      addTearDown(
          container.listen(paymentControllerProvider(_uidA), (_, __) {}).close);

      final state = container.read(paymentControllerProvider(_uidA));

      expect(state.phase, PaymentPhase.creatingPayment);
      expect(state.orderId, isNull);
    });

    test(
        'startCheckout() creates the order, opens the payment page, and moves to waitingForPayment',
        () {
      fakeAsync((async) {
        String? openedUrl;
        final container = _makeContainer(
          FakePaymentRepository(
            createCheckout: ({storeId, required items}) async =>
                const CheckoutResultModel(
              orderId: 'order-1',
              storeId: 'store-1',
              amount: 250,
              paymentId: 'pay-1',
              paymentUrl: 'https://pay.example/order-1',
            ),
            openPaymentUrl: (url) async => openedUrl = url,
            getCheckoutStatus: (orderId) async =>
                const OrderStatusModel(paymentStatus: 'PAYMENT_INITIATED'),
          ),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(paymentControllerProvider(_uidA), (_, __) {})
            .close);

        container
            .read(paymentControllerProvider(_uidA).notifier)
            .startCheckout(storeId: 'store-1', items: _items);
        async.flushMicrotasks();

        final state = container.read(paymentControllerProvider(_uidA));
        expect(state.phase, PaymentPhase.waitingForCustomer);
        expect(state.orderId, 'order-1');
        expect(state.paymentId, 'pay-1');
        expect(state.amount, 250);
        expect(openedUrl, 'https://pay.example/order-1');
      });
    });

    test('startCheckout() surfaces a failure as the error phase', () {
      fakeAsync((async) {
        final container = _makeContainer(
          FakePaymentRepository(
            createCheckout: ({storeId, required items}) async =>
                throw Exception('store not found'),
          ),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(paymentControllerProvider(_uidA), (_, __) {})
            .close);

        container
            .read(paymentControllerProvider(_uidA).notifier)
            .startCheckout(items: _items);
        async.flushMicrotasks();

        final state = container.read(paymentControllerProvider(_uidA));
        expect(state.phase, PaymentPhase.error);
        expect(state.errorMessage, isNotNull);
      });
    });

    group('polling — payment state transitions', () {
      ProviderContainer startedContainer(String Function() paymentStatus,
          {String? failureReason}) {
        final container = _makeContainer(
          FakePaymentRepository(
            createCheckout: ({storeId, required items}) async =>
                const CheckoutResultModel(
              orderId: 'order-1',
              paymentId: 'pay-1',
              paymentUrl: 'https://pay.example/order-1',
            ),
            getCheckoutStatus: (orderId) async => OrderStatusModel(
              paymentStatus: paymentStatus(),
              transactionId: 'txn-1',
              paymentMethod: 'CARD',
              failureReason: failureReason,
            ),
          ),
        );
        return container;
      }

      test('PAYMENT_PROCESSING keeps polling and moves to the processing phase',
          () {
        fakeAsync((async) {
          final container = startedContainer(() => 'PAYMENT_PROCESSING');
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          container
              .read(paymentControllerProvider(_uidA).notifier)
              .startCheckout(items: _items);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 2));

          final state = container.read(paymentControllerProvider(_uidA));
          expect(state.phase, PaymentPhase.paymentProcessing);
          expect(state.transactionId, 'txn-1');
          expect(state.paymentMethod, 'CARD');
        });
      });

      test('PAYMENT_COMPLETED moves to approved and stops polling', () {
        fakeAsync((async) {
          var callCount = 0;
          final container = _makeContainer(
            FakePaymentRepository(
              createCheckout: ({storeId, required items}) async =>
                  const CheckoutResultModel(
                      orderId: 'order-1', paymentId: 'pay-1'),
              getCheckoutStatus: (orderId) async {
                callCount++;
                return const OrderStatusModel(
                    paymentStatus: 'PAYMENT_COMPLETED', transactionId: 'txn-1');
              },
            ),
          );
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          container
              .read(paymentControllerProvider(_uidA).notifier)
              .startCheckout(items: _items);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 2));

          expect(container.read(paymentControllerProvider(_uidA)).phase,
              PaymentPhase.paymentSuccessful);
          final countAtApproval = callCount;

          // Polling must have stopped — elapsing further time doesn't call the status endpoint again.
          async.elapse(const Duration(seconds: 10));
          expect(callCount, countAtApproval);
        });
      });

      test('PAYMENT_FAILED moves to declined and carries the failure reason',
          () {
        fakeAsync((async) {
          final container = startedContainer(() => 'PAYMENT_FAILED',
              failureReason: 'Card declined by issuer');
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          container
              .read(paymentControllerProvider(_uidA).notifier)
              .startCheckout(items: _items);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 2));

          final state = container.read(paymentControllerProvider(_uidA));
          expect(state.phase, PaymentPhase.paymentFailed);
          expect(state.failureReason, 'Card declined by issuer');
        });
      });

      test(
          'PAYMENT_CANCELLED (cancelled from the payment page itself) moves to cancelled',
          () {
        fakeAsync((async) {
          final container = startedContainer(() => 'PAYMENT_CANCELLED');
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          container
              .read(paymentControllerProvider(_uidA).notifier)
              .startCheckout(items: _items);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 2));

          expect(container.read(paymentControllerProvider(_uidA)).phase,
              PaymentPhase.paymentCancelled);
        });
      });

      test(
          'never reaching a terminal status times out after the polling budget is exhausted',
          () {
        fakeAsync((async) {
          final container = startedContainer(() => 'PAYMENT_INITIATED');
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          container
              .read(paymentControllerProvider(_uidA).notifier)
              .startCheckout(items: _items);
          async.flushMicrotasks();

          // 90 attempts at 2s each — comfortably past the controller's poll budget.
          async.elapse(const Duration(seconds: 200));

          expect(container.read(paymentControllerProvider(_uidA)).phase,
              PaymentPhase.paymentExpired);
        });
      });
    });

    group('checkStatusNow() — deep link / app-resume fast path', () {
      test('checks status immediately without waiting for the poll timer', () {
        fakeAsync((async) {
          var statusCallCount = 0;
          final container = _makeContainer(
            FakePaymentRepository(
              createCheckout: ({storeId, required items}) async =>
                  const CheckoutResultModel(
                      orderId: 'order-1', paymentId: 'pay-1'),
              getCheckoutStatus: (orderId) async {
                statusCallCount++;
                return const OrderStatusModel(
                    paymentStatus: 'PAYMENT_COMPLETED', transactionId: 'txn-1');
              },
            ),
          );
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          final notifier =
              container.read(paymentControllerProvider(_uidA).notifier);
          notifier.startCheckout(items: _items);
          async.flushMicrotasks();
          expect(statusCallCount, 0);

          notifier.checkStatusNow();
          async.flushMicrotasks();

          expect(statusCallCount, 1);
          expect(container.read(paymentControllerProvider(_uidA)).phase,
              PaymentPhase.paymentSuccessful);
        });
      });

      test('does nothing before an order exists', () {
        fakeAsync((async) {
          var statusCallCount = 0;
          final container = _makeContainer(
            FakePaymentRepository(
              getCheckoutStatus: (orderId) async {
                statusCallCount++;
                return const OrderStatusModel(
                    paymentStatus: 'PAYMENT_COMPLETED');
              },
            ),
          );
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          container
              .read(paymentControllerProvider(_uidA).notifier)
              .checkStatusNow();
          async.flushMicrotasks();

          expect(statusCallCount, 0);
        });
      });

      test('does nothing once the payment has already reached a terminal phase',
          () {
        fakeAsync((async) {
          var statusCallCount = 0;
          final container = _makeContainer(
            FakePaymentRepository(
              createCheckout: ({storeId, required items}) async =>
                  const CheckoutResultModel(
                      orderId: 'order-1', paymentId: 'pay-1'),
              getCheckoutStatus: (orderId) async {
                statusCallCount++;
                return const OrderStatusModel(
                    paymentStatus: 'PAYMENT_COMPLETED');
              },
            ),
          );
          addTearDown(container.dispose);
          addTearDown(container
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);

          final notifier =
              container.read(paymentControllerProvider(_uidA).notifier);
          notifier.startCheckout(items: _items);
          async.flushMicrotasks();

          notifier.checkStatusNow();
          async.flushMicrotasks();
          expect(container.read(paymentControllerProvider(_uidA)).phase,
              PaymentPhase.paymentSuccessful);
          final callsAtApproval = statusCallCount;

          notifier.checkStatusNow();
          async.flushMicrotasks();

          expect(statusCallCount, callsAtApproval);
        });
      });
    });

    test(
        'retry() switches to the brand-new order the backend creates and polls that order, never the dead one',
        () {
      fakeAsync((async) {
        // The backend never reopens order-1's (now-terminated) hosted Payment
        // Page link — it creates a genuinely new order-2 with its own fresh
        // link (see payment.service.js#retryPayment). The controller must
        // adopt that new orderId, or polling would chase order-1 forever.
        final urls = <String>[];
        final statusQueriedOrderIds = <String>[];
        final container = _makeContainer(
          FakePaymentRepository(
            createCheckout: ({storeId, required items}) async =>
                const CheckoutResultModel(
              orderId: 'order-1',
              storeId: 'store-1',
              paymentId: 'pay-1',
              paymentUrl: 'https://pay.example/first',
            ),
            retryPayment: ({required orderId, required storeId}) async =>
                const CheckoutResultModel(
              orderId: 'order-2',
              paymentId: 'pay-2',
              paymentUrl: 'https://pay.example/retry',
            ),
            openPaymentUrl: (url) async => urls.add(url),
            getCheckoutStatus: (orderId) async {
              statusQueriedOrderIds.add(orderId);
              return const OrderStatusModel(paymentStatus: 'PAYMENT_FAILED');
            },
          ),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(paymentControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(paymentControllerProvider(_uidA).notifier);
        notifier.startCheckout(storeId: 'store-1', items: _items);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        expect(container.read(paymentControllerProvider(_uidA)).phase,
            PaymentPhase.paymentFailed);
        expect(statusQueriedOrderIds, everyElement('order-1'));

        notifier.retry();
        async.flushMicrotasks();

        var state = container.read(paymentControllerProvider(_uidA));
        expect(state.orderId, 'order-2');
        expect(state.paymentId, 'pay-2');
        expect(state.phase, PaymentPhase.waitingForCustomer);
        expect(
            urls, ['https://pay.example/first', 'https://pay.example/retry']);

        // Polling resumed after the retry — against the NEW order only.
        statusQueriedOrderIds.clear();
        async.elapse(const Duration(seconds: 2));
        expect(statusQueriedOrderIds, isNotEmpty);
        expect(statusQueriedOrderIds, everyElement('order-2'));
      });
    });

    test('cancel() cancels the payment, moves to cancelled, and stops polling',
        () {
      fakeAsync((async) {
        String? cancelledPaymentId;
        var statusCallCount = 0;
        final container = _makeContainer(
          FakePaymentRepository(
            createCheckout: ({storeId, required items}) async =>
                const CheckoutResultModel(
                    orderId: 'order-1', paymentId: 'pay-1'),
            getCheckoutStatus: (orderId) async {
              statusCallCount++;
              return const OrderStatusModel(paymentStatus: 'PAYMENT_INITIATED');
            },
            cancelPayment: (paymentId) async => cancelledPaymentId = paymentId,
          ),
        );
        addTearDown(container.dispose);
        addTearDown(container
            .listen(paymentControllerProvider(_uidA), (_, __) {})
            .close);

        final notifier =
            container.read(paymentControllerProvider(_uidA).notifier);
        notifier.startCheckout(items: _items);
        async.flushMicrotasks();

        notifier.cancel();
        async.flushMicrotasks();

        expect(cancelledPaymentId, 'pay-1');
        expect(container.read(paymentControllerProvider(_uidA)).phase,
            PaymentPhase.paymentCancelled);

        final callsAtCancel = statusCallCount;
        async.elapse(const Duration(seconds: 10));
        expect(statusCallCount, callsAtCancel);
      });
    });

    group('cross-user isolation (see docs/22_DEVELOPMENT_ROADMAP.md)', () {
      test('two different uids never share checkout state', () {
        fakeAsync((async) {
          final containerA = _makeContainer(
            FakePaymentRepository(
              createCheckout: ({storeId, required items}) async =>
                  const CheckoutResultModel(
                      orderId: 'order-a', paymentId: 'pay-a'),
            ),
          );
          addTearDown(containerA.dispose);
          final containerB = _makeContainer(FakePaymentRepository());
          addTearDown(containerB.dispose);
          addTearDown(containerA
              .listen(paymentControllerProvider(_uidA), (_, __) {})
              .close);
          addTearDown(containerB
              .listen(paymentControllerProvider(_uidB), (_, __) {})
              .close);

          containerA
              .read(paymentControllerProvider(_uidA).notifier)
              .startCheckout(items: _items);
          async.flushMicrotasks();

          final stateA = containerA.read(paymentControllerProvider(_uidA));
          final stateB = containerB.read(paymentControllerProvider(_uidB));

          expect(stateA.orderId, 'order-a');
          expect(stateB.orderId, isNull);
          expect(stateB.phase, PaymentPhase.creatingPayment);
        });
      });
    });
  });
}
