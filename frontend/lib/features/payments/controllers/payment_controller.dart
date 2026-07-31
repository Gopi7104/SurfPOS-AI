import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checkout_item.dart';
import '../models/payment_failure.dart';
import '../models/payment_phase.dart';
import '../models/payment_state.dart';
import '../providers/payment_providers.dart';

/// Checkout state for exactly one Firebase uid (see [paymentControllerProvider]
/// — a `.family` provider, the uid is this notifier's `arg`) — same
/// cross-user isolation pattern every controller in this app follows.
///
/// Owns the whole Checkout → Payment Page → poll → result lifecycle:
/// [startCheckout] creates the order/payment and opens Surfboard's hosted
/// Payment Page, then polls [PaymentRepository.getCheckoutStatus] every few
/// seconds until the payment reaches a terminal state (or times out).
class PaymentController
    extends AutoDisposeFamilyNotifier<PaymentState, String> {
  Timer? _pollTimer;
  int _pollAttempts = 0;

  static const _pollInterval = Duration(seconds: 2);
  // ~3 minutes — long enough for a customer to complete card entry on the
  // hosted page, short enough that a screen isn't left polling forever.
  static const _maxPollAttempts = 90;

  @override
  PaymentState build(String uid) {
    ref.onDispose(_stopPolling);
    return const PaymentState();
  }

  Future<void> startCheckout(
      {String? storeId, required List<CheckoutItem> items}) async {
    _stopPolling();
    state = const PaymentState(phase: PaymentPhase.creatingPayment);
    try {
      final repository = ref.read(paymentRepositoryProvider);
      final result =
          await repository.createCheckout(storeId: storeId, items: items);
      state = state.copyWith(
        phase: PaymentPhase.waitingForPayment,
        orderId: result.orderId,
        storeId: result.storeId ?? storeId,
        paymentId: result.paymentId,
        amount: result.amount,
        paymentUrl: result.paymentUrl,
      );
      if (result.paymentUrl != null) {
        await repository.openPaymentUrl(result.paymentUrl!);
      }
      _startPolling();
    } catch (error) {
      state = state.copyWith(
        phase: PaymentPhase.error,
        errorMessage: PaymentFailure.fromException(error).message,
      );
    }
  }

  /// Re-initiates payment against the same order — per Surfboard's payment
  /// lifecycle, a cancelled/failed/timed-out attempt doesn't need a new order.
  Future<void> retry() async {
    final orderId = state.orderId;
    final storeId = state.storeId;
    if (orderId == null || storeId == null) return;

    _stopPolling();
    state = state.copyWith(
      phase: PaymentPhase.creatingPayment,
      clearErrorMessage: true,
      clearFailureReason: true,
    );
    try {
      final repository = ref.read(paymentRepositoryProvider);
      final result =
          await repository.retryPayment(orderId: orderId, storeId: storeId);
      state = state.copyWith(
        phase: PaymentPhase.waitingForPayment,
        paymentId: result.paymentId,
        paymentUrl: result.paymentUrl,
      );
      if (result.paymentUrl != null) {
        await repository.openPaymentUrl(result.paymentUrl!);
      }
      _startPolling();
    } catch (error) {
      state = state.copyWith(
        phase: PaymentPhase.error,
        errorMessage: PaymentFailure.fromException(error).message,
      );
    }
  }

  /// Re-opens the hosted Payment Page — for when the customer's browser tab
  /// was closed/backgrounded by mistake while still `waitingForPayment`.
  Future<void> reopenPaymentUrl() async {
    final url = state.paymentUrl;
    if (url == null) return;
    try {
      await ref.read(paymentRepositoryProvider).openPaymentUrl(url);
    } catch (_) {
      // Best-effort — the status screen keeps polling regardless.
    }
  }

  Future<void> cancel() async {
    _stopPolling();
    final paymentId = state.paymentId;
    if (paymentId == null) {
      state = state.copyWith(phase: PaymentPhase.cancelled);
      return;
    }
    try {
      await ref.read(paymentRepositoryProvider).cancelPayment(paymentId);
    } catch (_) {
      // Best-effort — Surfboard may already consider it completed/failed by
      // the time this reaches it; the cashier backing out is final either way.
    }
    state = state.copyWith(phase: PaymentPhase.cancelled);
  }

  void _startPolling() {
    _pollAttempts = 0;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    final orderId = state.orderId;
    if (orderId == null) {
      _stopPolling();
      return;
    }

    _pollAttempts++;
    if (_pollAttempts > _maxPollAttempts) {
      _stopPolling();
      state = state.copyWith(phase: PaymentPhase.timedOut);
      return;
    }

    try {
      final status =
          await ref.read(paymentRepositoryProvider).getCheckoutStatus(orderId);
      final phase = _mapPhase(status.paymentStatus);
      state = state.copyWith(
        phase: phase,
        transactionId: status.transactionId,
        paymentMethod: status.paymentMethod,
        failureReason: status.failureReason,
      );
      if (phase.isTerminal) {
        _stopPolling();
      }
    } catch (error) {
      // A single failed poll is likely a transient network hiccup — keep
      // retrying until _maxPollAttempts rather than failing the whole flow.
      if (_pollAttempts >= _maxPollAttempts) {
        _stopPolling();
        state = state.copyWith(
          phase: PaymentPhase.error,
          errorMessage: PaymentFailure.fromException(error).message,
        );
      }
    }
  }

  PaymentPhase _mapPhase(String? paymentStatus) {
    return switch (paymentStatus) {
      'PAYMENT_COMPLETED' => PaymentPhase.approved,
      'PAYMENT_FAILED' => PaymentPhase.declined,
      'PAYMENT_CANCELLED' => PaymentPhase.cancelled,
      'PAYMENT_PROCESSING' || 'PAYMENT_PROCESSED' => PaymentPhase.processing,
      _ => PaymentPhase.waitingForPayment,
    };
  }
}
