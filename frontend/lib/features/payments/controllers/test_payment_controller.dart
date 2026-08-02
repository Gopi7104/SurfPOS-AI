import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_phase.dart';
import '../models/payment_state.dart';
import '../models/test_payment_result.dart';
import '../providers/payment_providers.dart';

/// Development-only counterpart to [PaymentController] — drives the exact
/// same [PaymentState]/[PaymentPhase] machine, but every step is a timed,
/// offline simulation through [TestPaymentRepository] instead of a real
/// Surfboard order. See docs/22_DEVELOPMENT_ROADMAP.md Phase 4.5.
///
/// [TestPaymentStatusPage] reuses [PaymentState]/[PaymentPhase] purely so it
/// can build a [ReceiptModel] the same way the real flow does — it renders
/// its own step labels rather than [PaymentProgressSteps], since this flow's
/// spec ("Creating Payment / Authorizing / Processing / Payment Successful")
/// doesn't match the real flow's "Waiting For Customer" wording.
class TestPaymentController
    extends AutoDisposeFamilyNotifier<PaymentState, String> {
  static const _stepDelay = Duration(milliseconds: 700);

  TestPaymentResult? _result;

  /// The fake payment fields generated for the in-flight/just-completed run
  /// — null until [run] reaches its first step. Carries the fields
  /// [PaymentState] has no room for (receipt number, approval code).
  TestPaymentResult? get result => _result;

  @override
  PaymentState build(String uid) {
    return const PaymentState(phase: PaymentPhase.creatingPayment);
  }

  Future<void> run() async {
    _result = null;
    state = const PaymentState(phase: PaymentPhase.creatingPayment);
    await Future.delayed(_stepDelay);

    final repository = ref.read(testPaymentRepositoryProvider);
    final checkout = await repository.createCheckout(items: const []);
    final result = TestPaymentResult.generate();
    _result = result;
    state = state.copyWith(
      phase: PaymentPhase.waitingForCustomer,
      orderId: checkout.orderId,
      paymentId: result.paymentId,
    );
    await Future.delayed(_stepDelay);

    state = state.copyWith(phase: PaymentPhase.paymentProcessing);
    await Future.delayed(_stepDelay);

    state = state.copyWith(
      phase: PaymentPhase.paymentSuccessful,
      transactionId: result.transactionId,
      paymentMethod: TestPaymentResult.method,
    );
  }
}
