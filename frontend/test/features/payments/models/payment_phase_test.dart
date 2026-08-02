import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/payments/models/payment_phase.dart';

void main() {
  group('PaymentPhase', () {
    test(
        'isTerminal is true only for paymentSuccessful/paymentFailed/paymentCancelled/paymentExpired/error',
        () {
      const terminal = {
        PaymentPhase.paymentSuccessful,
        PaymentPhase.paymentFailed,
        PaymentPhase.paymentCancelled,
        PaymentPhase.paymentExpired,
        PaymentPhase.error,
      };
      const nonTerminal = {
        PaymentPhase.creatingPayment,
        PaymentPhase.waitingForCustomer,
        PaymentPhase.paymentProcessing,
      };

      for (final phase in terminal) {
        expect(phase.isTerminal, isTrue, reason: '$phase should be terminal');
      }
      for (final phase in nonTerminal) {
        expect(phase.isTerminal, isFalse,
            reason: '$phase should not be terminal');
      }
    });

    test(
        'canRetry is true only for paymentFailed/paymentCancelled/paymentExpired/error',
        () {
      const retryable = {
        PaymentPhase.paymentFailed,
        PaymentPhase.paymentCancelled,
        PaymentPhase.paymentExpired,
        PaymentPhase.error,
      };
      const notRetryable = {
        PaymentPhase.creatingPayment,
        PaymentPhase.waitingForCustomer,
        PaymentPhase.paymentProcessing,
        PaymentPhase.paymentSuccessful,
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
