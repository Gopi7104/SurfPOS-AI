import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../features/receipt/models/receipt_line_item.dart';
import '../../../features/receipt/models/receipt_model.dart';
import '../controllers/payment_controller.dart';
import '../models/checkout_item.dart';
import '../models/payment_phase.dart';
import '../models/payment_state.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_processing_timeline.dart';
import '../widgets/payment_progress_steps.dart';
import '../widgets/payment_status_indicator.dart';
import '../widgets/payment_success_view.dart';
import 'payment_success_page.dart';

/// Checkout's payment-status screen — pushed after the merchant confirms the
/// Payment Summary dialog. Owns starting the checkout attempt on first
/// build; every subsequent frame just reflects [PaymentController]'s state.
/// Once the payment reaches `paymentSuccessful`, this replaces itself with
/// [PaymentSuccessPage], which then hands off to the Receipt once the
/// cashier taps through — see docs/22_DEVELOPMENT_ROADMAP.md, Phase 5.
class PaymentStatusPage extends ConsumerStatefulWidget {
  const PaymentStatusPage({
    required this.uid,
    required this.storeId,
    required this.items,
    required this.merchantName,
    required this.storeName,
    required this.receiptItems,
    required this.onDone,
    this.customerName,
    this.customerPhone,
    super.key,
  });

  final String uid;
  final String storeId;
  final List<CheckoutItem> items;

  final String merchantName;
  final String storeName;

  /// Line-item snapshot for the eventual [ReceiptModel] — built by the
  /// caller (BillingPage) from the same cart [items] was derived from, since
  /// this feature doesn't depend on Billing's `CartItemModel` directly (see
  /// `ReceiptModel.fromPayment`'s header comment).
  final List<ReceiptLineItem> receiptItems;

  /// Optional walk-in-customer info from Billing's Customer Details step —
  /// never sent to any backend, only carried through to the Receipt (see
  /// `CustomerDetails`'s own header comment).
  final String? customerName;
  final String? customerPhone;

  /// Called when the merchant dismisses a terminal (non-success) result or
  /// taps "New Sale" from the Receipt screen — the caller (BillingPage)
  /// clears the cart and pops back to Billing.
  final VoidCallback onDone;

  @override
  ConsumerState<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends ConsumerState<PaymentStatusPage>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Captured once, the moment the payment first succeeds — reused for both
  /// the Success Screen's "Date" row and [ReceiptModel.completedAt] so the
  /// two never disagree, even though the Receipt navigation itself is
  /// delayed by [_successScreenDuration].
  DateTime? _succeededAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentControllerProvider(widget.uid).notifier).startCheckout(
            storeId: widget.storeId,
            items: widget.items,
          );
    });
    // Primary "customer is done" signal — Surfboard's hosted Payment Page
    // redirects the Custom Tab to this app's `surfpos://payment/...` deep
    // link (see backend/src/controllers/paymentRedirect.controller.js),
    // which Android hands to this already-running Activity (singleTop).
    // Both success and failure links just mean "go check now" — the real
    // outcome always comes from Surfboard's own order status, never the
    // redirect URL itself (web-guides/payment-page.md's own guidance).
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      // TEMPORARY TRACE — payment confirmation flow investigation.
      debugPrint(
          '[PAYMENT_TRACE] step=5/6 event=deep_link_received uri=$uri ts=${DateTime.now().toIso8601String()}');
      if (uri.scheme == 'surfpos' && uri.host == 'payment') {
        debugPrint(
            '[PAYMENT_TRACE] step=7 event=PaymentStatusPage_matched orderId=${uri.queryParameters['orderId']} ts=${DateTime.now().toIso8601String()}');
        _checkStatusNow();
      } else {
        debugPrint(
            '[PAYMENT_TRACE] step=7 event=uri_did_not_match scheme=${uri.scheme} host=${uri.host}');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Fallback "customer is done" signal for when the redirect deep link
    // isn't available (e.g. the customer just closes the Custom Tab instead
    // of reaching a redirect) — per Phase 5's "detect browser close and
    // immediately verify the payment status" requirement.
    if (state == AppLifecycleState.resumed) {
      _checkStatusNow();
    }
  }

  void _checkStatusNow() {
    debugPrint(
        '[PAYMENT_TRACE] step=8 event=checkStatusNow_called ts=${DateTime.now().toIso8601String()}');
    ref.read(paymentControllerProvider(widget.uid).notifier).checkStatusNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _navigateToSuccessPage(PaymentState state) {
    final completedAt = _succeededAt ?? DateTime.now();
    final receipt = ReceiptModel.fromPayment(
      state: state,
      merchantName: widget.merchantName,
      storeName: widget.storeName,
      items: widget.receiptItems,
      completedAt: completedAt,
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(
          amount: state.amount,
          reference: state.paymentId ?? state.orderId,
          transactionId: state.transactionId,
          merchantName: widget.merchantName,
          completedAt: completedAt,
          uid: widget.uid,
          receipt: receipt,
          onNewSale: widget.onDone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentControllerProvider(widget.uid),
        (previous, next) {
      debugPrint('[PAYMENT_TRACE] step=12 event=state_updated '
          'previousPhase=${previous?.phase} newPhase=${next.phase} '
          'orderId=${next.orderId} paymentId=${next.paymentId} transactionId=${next.transactionId} '
          'ts=${DateTime.now().toIso8601String()}');
      final justSucceeded = next.phase == PaymentPhase.paymentSuccessful &&
          previous?.phase != PaymentPhase.paymentSuccessful;
      if (justSucceeded) {
        _succeededAt ??= DateTime.now();
        debugPrint(
            '[PAYMENT_TRACE] step=13 event=navigate_to_success_page orderId=${next.orderId} ts=${DateTime.now().toIso8601String()}');
        _navigateToSuccessPage(next);
      }
    });
    final state = ref.watch(paymentControllerProvider(widget.uid));
    final notifier = ref.read(paymentControllerProvider(widget.uid).notifier);

    return PopScope(
      canPop: state.phase.isTerminal,
      child: Scaffold(
        appBar: const AppTopBar(title: 'Payment'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                PaymentProgressSteps(phase: state.phase),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: SingleChildScrollView(
                    child: state.phase == PaymentPhase.paymentSuccessful
                        ? PaymentSuccessView(
                            amount: state.amount,
                            reference: state.paymentId ?? state.orderId,
                            transactionId: state.transactionId,
                            merchantName: widget.merchantName,
                            completedAt: _succeededAt ?? DateTime.now(),
                          )
                        : Column(
                            children: [
                              PaymentStatusIndicator(phase: state.phase),
                              const SizedBox(height: AppSpacing.lg),
                              Text(_titleFor(state.phase),
                                  style: AppTypography.headingSM,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _messageFor(state),
                                style: AppTypography.bodyMD
                                    .copyWith(color: AppColors.textGrey),
                                textAlign: TextAlign.center,
                              ),
                              if (!state.phase.isTerminal) ...[
                                const SizedBox(height: AppSpacing.lg),
                                PaymentProcessingTimeline(phase: state.phase),
                              ] else if (state.amount != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '\$${state.amount!.toStringAsFixed(2)}',
                                  style: AppTypography.headingSM
                                      .copyWith(color: AppColors.primary),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                _Actions(
                    state: state, notifier: notifier, onDone: widget.onDone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(PaymentPhase phase) => switch (phase) {
        PaymentPhase.creatingPayment => 'Creating Payment…',
        PaymentPhase.waitingForCustomer => 'Waiting For Customer',
        PaymentPhase.paymentProcessing => 'Payment Processing…',
        PaymentPhase.paymentSuccessful => 'Payment Successful',
        PaymentPhase.paymentFailed => 'Payment Failed',
        PaymentPhase.paymentCancelled => 'Payment Cancelled',
        PaymentPhase.paymentExpired => 'Payment Expired',
        PaymentPhase.error => 'Something Went Wrong',
      };

  String _messageFor(PaymentState state) => switch (state.phase) {
        PaymentPhase.creatingPayment => 'Setting up this order with Surfboard.',
        PaymentPhase.waitingForCustomer =>
          'Ask the customer to complete payment on the page that just opened.',
        PaymentPhase.paymentProcessing =>
          'The card is being authorized. This only takes a moment.',
        PaymentPhase.paymentSuccessful => 'The sale is complete.',
        PaymentPhase.paymentFailed =>
          state.failureReason ?? 'The customer\'s card was declined.',
        PaymentPhase.paymentCancelled => 'This payment was cancelled.',
        PaymentPhase.paymentExpired =>
          'The customer didn\'t complete payment in time.',
        PaymentPhase.error => state.errorMessage ?? 'Please try again.',
      };
}

class _Actions extends StatelessWidget {
  const _Actions(
      {required this.state, required this.notifier, required this.onDone});

  final PaymentState state;
  final PaymentController notifier;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case PaymentPhase.paymentSuccessful:
        return AppPrimaryButton(label: 'Done', onPressed: onDone);
      case PaymentPhase.paymentFailed:
      case PaymentPhase.paymentExpired:
      case PaymentPhase.error:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Back to Cart'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: AppPrimaryButton(
                    label: 'Retry', onPressed: notifier.retry)),
          ],
        );
      case PaymentPhase.paymentCancelled:
        return AppPrimaryButton(label: 'Back to Cart', onPressed: onDone);
      case PaymentPhase.creatingPayment:
      case PaymentPhase.waitingForCustomer:
      case PaymentPhase.paymentProcessing:
        return OutlinedButton(
          onPressed: notifier.cancel,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: const Text('Cancel'),
        );
    }
  }
}
