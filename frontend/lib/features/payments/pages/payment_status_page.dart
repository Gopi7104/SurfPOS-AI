import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../controllers/payment_controller.dart';
import '../models/checkout_item.dart';
import '../models/payment_phase.dart';
import '../models/payment_state.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_progress_steps.dart';
import '../widgets/payment_status_indicator.dart';

/// Checkout's payment-status screen — pushed after the merchant confirms the
/// Payment Summary dialog. Owns starting the checkout attempt on first
/// build; every subsequent frame just reflects [PaymentController]'s state.
/// See docs/22_DEVELOPMENT_ROADMAP.md, Phase 4 — no receipt/printing here,
/// this screen ends at "display success/failure".
class PaymentStatusPage extends ConsumerStatefulWidget {
  const PaymentStatusPage({
    required this.uid,
    required this.storeId,
    required this.items,
    required this.onDone,
    super.key,
  });

  final String uid;
  final String storeId;
  final List<CheckoutItem> items;

  /// Called when the merchant dismisses a terminal result — the caller
  /// (BillingPage) clears the cart and pops back to Billing.
  final VoidCallback onDone;

  @override
  ConsumerState<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends ConsumerState<PaymentStatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentControllerProvider(widget.uid).notifier).startCheckout(
            storeId: widget.storeId,
            items: widget.items,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
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
                        if (state.amount != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '\$${state.amount!.toStringAsFixed(2)}',
                            style: AppTypography.headingSM
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                        if (state.phase == PaymentPhase.approved) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _ApprovedDetailsCard(state: state),
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
        PaymentPhase.waitingForPayment => 'Waiting For Payment',
        PaymentPhase.processing => 'Processing…',
        PaymentPhase.approved => 'Payment Approved',
        PaymentPhase.declined => 'Payment Declined',
        PaymentPhase.cancelled => 'Payment Cancelled',
        PaymentPhase.timedOut => 'Payment Timed Out',
        PaymentPhase.error => 'Something Went Wrong',
      };

  String _messageFor(PaymentState state) => switch (state.phase) {
        PaymentPhase.creatingPayment => 'Setting up this order with Surfboard.',
        PaymentPhase.waitingForPayment =>
          'Ask the customer to complete payment on the page that just opened in their browser.',
        PaymentPhase.processing =>
          'The card is being authorized. This only takes a moment.',
        PaymentPhase.approved => 'The sale is complete.',
        PaymentPhase.declined =>
          state.failureReason ?? 'The customer\'s card was declined.',
        PaymentPhase.cancelled => 'This payment was cancelled.',
        PaymentPhase.timedOut =>
          'The customer didn\'t complete payment in time.',
        PaymentPhase.error => state.errorMessage ?? 'Please try again.',
      };
}

class _ApprovedDetailsCard extends StatelessWidget {
  const _ApprovedDetailsCard({required this.state});

  final PaymentState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(label: 'Payment ID', value: state.paymentId),
          _DetailRow(label: 'Order ID', value: state.orderId),
          _DetailRow(label: 'Transaction ID', value: state.transactionId),
          const _DetailRow(label: 'Payment Status', value: 'Approved'),
          _DetailRow(
            label: 'Amount',
            value: state.amount == null
                ? null
                : '\$${state.amount!.toStringAsFixed(2)}',
          ),
          _DetailRow(label: 'Payment Method', value: state.paymentMethod),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
          Flexible(
            child: Text(
              value ?? '—',
              style: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
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
      case PaymentPhase.approved:
        return AppPrimaryButton(label: 'Done', onPressed: onDone);
      case PaymentPhase.declined:
      case PaymentPhase.timedOut:
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
      case PaymentPhase.cancelled:
        return AppPrimaryButton(label: 'Back to Cart', onPressed: onDone);
      case PaymentPhase.creatingPayment:
      case PaymentPhase.waitingForPayment:
      case PaymentPhase.processing:
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
