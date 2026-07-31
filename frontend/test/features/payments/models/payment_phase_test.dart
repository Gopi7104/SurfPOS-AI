import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/payments/models/payment_phase.dart';

void main() {
  group('PaymentPhase', () {
    test(
        'isTerminal is true only for approved/declined/cancelled/timedOut/error',
        () {
      const terminal = {
        PaymentPhase.approved,
        PaymentPhase.declined,
        PaymentPhase.cancelled,
        PaymentPhase.timedOut,
        PaymentPhase.error,
      };
      const nonTerminal = {
        PaymentPhase.creatingPayment,
        PaymentPhase.waitingForPayment,
        PaymentPhase.processing,
      };

      for (final phase in terminal) {
        expect(phase.isTerminal, isTrue, reason: '$phase should be terminal');
      }
      for (final phase in nonTerminal) {
        expect(phase.isTerminal, isFalse,
            reason: '$phase should not be terminal');
      }
    });

    test('canRetry is true only for declined/cancelled/timedOut/error', () {
      const retryable = {
        PaymentPhase.declined,
        PaymentPhase.cancelled,
        PaymentPhase.timedOut,
        PaymentPhase.error,
      };
      const notRetryable = {
        PaymentPhase.creatingPayment,
        PaymentPhase.waitingForPayment,
        PaymentPhase.processing,
        PaymentPhase.approved,
      };

      for (final phase in retryable) {
        expect(phase.canRetry, isTrue, reason: '$phase should be retryable');
      }
      for (final phase in notRetryable) {
        expect(phase.canRetry, isFalse,
            reason: '$phase should not be retryable');
      }
    });
  });
}
