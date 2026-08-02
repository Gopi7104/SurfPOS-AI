import 'dart:async';

import 'package:flutter/foundation.dart';
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
        phase: PaymentPhase.waitingForCustomer,
        orderId: result.orderId,
        storeId: result.storeId ?? storeId,
        paymentId: result.paymentId,
        amount: result.amount,
        subtotal: result.subtotal,
        discountTotal: result.discountTotal,
        taxTotal: result.taxTotal,
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

  /// Retries payment for the same cart — creates a brand-new order (and its
  /// own fresh hosted Payment Page link) rather than reopening the previous
  /// order's link. Surfboard's hosted Payment Page is a one-shot session: once
  /// the customer's browser reaches it and the attempt concludes (success,
  /// decline, or cancel), that link is done — reopening it shows Surfboard's
  /// own "Invalid or Expired Link" page, which is exactly the bug this
  /// avoids. The backend returns a NEW [CheckoutResultModel.orderId], which
  /// this must switch to — polling would never resolve against the old,
  /// now-abandoned order.
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
        phase: PaymentPhase.waitingForCustomer,
        orderId: result.orderId,
        paymentId: result.paymentId,
        paymentUrl: result.paymentUrl,
        // Re-priced against the current catalog by the backend — see
        // payment.service.js#createOrderAndLink — so refresh these too
        // rather than leaving the original attempt's snapshot in place.
        amount: result.amount,
        subtotal: result.subtotal,
        discountTotal: result.discountTotal,
        taxTotal: result.taxTotal,
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
  /// was closed/backgrounded by mistake while still `waitingForCustomer`.
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
      state = state.copyWith(phase: PaymentPhase.paymentCancelled);
      return;
    }
    try {
      await ref.read(paymentRepositoryProvider).cancelPayment(paymentId);
    } catch (_) {
      // Best-effort — Surfboard may already consider it completed/failed by
      // the time this reaches it; the cashier backing out is final either way.
    }
    state = state.copyWith(phase: PaymentPhase.paymentCancelled);
  }

  /// Forces an immediate status check without waiting for the next timer
  /// tick — the fast path triggered by the redirect deep link landing
  /// ([PaymentDeepLinkListener]) or the app resuming from the Custom Tab
  /// (`WidgetsBindingObserver` in [PaymentStatusPage]), per Phase 5's
  /// "detect browser close and immediately verify the payment status"
  /// requirement. The periodic timer keeps running underneath this as the
  /// existing fallback safety net — this never replaces it, only shortcuts
  /// the wait when a stronger signal says the customer is done.
  Future<void> checkStatusNow() async {
    debugPrint(
        '[PAYMENT_TRACE] step=8 event=entered orderId=${state.orderId} phase=${state.phase} isTerminal=${state.phase.isTerminal}');
    if (state.orderId == null || state.phase.isTerminal) {
      debugPrint('[PAYMENT_TRACE] step=8 event=exited_early_return');
      return;
    }
    await _poll();
    debugPrint(
        '[PAYMENT_TRACE] step=8 event=exited orderId=${state.orderId} phase=${state.phase}');
  }

  void _startPolling() {
    _pollAttempts = 0;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // Guards against overlapping status checks: Timer.periodic fires on a
  // fixed 2s schedule regardless of whether the previous _poll() call's HTTP
  // request has finished. Without this flag, a single slow/stalled status
  // check (this network is flaky enough that it happens routinely) lets
  // every following timer tick pile another concurrent request on top of
  // it. checkStatusNow() (the redirect deep-link's fast path) shares this
  // guard too, since the deep link can legitimately fire more than once for
  // a single redirect. _pollAttempts only counts a request that actually
  // got to run — a tick skipped by this guard is not a wasted attempt.
  bool _pollInFlight = false;

  Future<void> _poll() async {
    if (_pollInFlight) return;
    _pollInFlight = true;
    try {
      final orderId = state.orderId;
      if (orderId == null) {
        _stopPolling();
        return;
      }

      _pollAttempts++;
      if (_pollAttempts > _maxPollAttempts) {
        _stopPolling();
        state = state.copyWith(phase: PaymentPhase.paymentExpired);
        return;
      }

      try {
        debugPrint(
            '[PAYMENT_TRACE] step=9 event=entered orderId=$orderId pollAttempt=$_pollAttempts');
        final status = await ref
            .read(paymentRepositoryProvider)
            .getCheckoutStatus(orderId);
        debugPrint(
            '[PAYMENT_TRACE] step=9 event=exited orderId=$orderId orderStatus=${status.orderStatus} paymentStatus=${status.paymentStatus} paymentId=${status.paymentId} transactionId=${status.transactionId}');
        final phase = _mapPhase(status.paymentStatus, status.orderStatus);
        debugPrint(
            '[PAYMENT_TRACE] step=12 event=phase_mapped rawPaymentStatus=${status.paymentStatus} mappedPhase=$phase');
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
    } finally {
      _pollInFlight = false;
    }
  }

  // `paymentStatus` comes from Surfboard's `payments[0].paymentStatus` (Fetch Order Status) or the
  // webhook cache — the primary signal. But Fetch Order Status can report the order itself as
  // already `PAYMENT_COMPLETED`/`PAYMENT_CANCELLED` (`orderStatus`) while its `payments[]` array
  // hasn't caught up yet, leaving `paymentStatus` null — confirmed live on the sandbox (see
  // webhook.controller.js's header comment on the same lag). Falling back to `orderStatus` here
  // stops the app polling forever in that window instead of just waiting for the webhook/next poll.
  PaymentPhase _mapPhase(String? paymentStatus, String? orderStatus) {
    return switch (paymentStatus) {
      'PAYMENT_COMPLETED' => PaymentPhase.paymentSuccessful,
      'PAYMENT_FAILED' => PaymentPhase.paymentFailed,
      'PAYMENT_CANCELLED' => PaymentPhase.paymentCancelled,
      'PAYMENT_PROCESSING' ||
      'PAYMENT_PROCESSED' =>
        PaymentPhase.paymentProcessing,
      _ => switch (orderStatus) {
          'PAYMENT_COMPLETED' ||
          'PARTIAL_PAYMENT_COMPLETED' =>
            PaymentPhase.paymentSuccessful,
          'PAYMENT_CANCELLED' => PaymentPhase.paymentCancelled,
          _ => PaymentPhase.waitingForCustomer,
        },
    };
  }
}
