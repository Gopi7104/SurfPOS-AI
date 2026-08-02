import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../receipt/models/receipt_line_item.dart';
import '../../receipt/models/receipt_model.dart';
import '../../receipt/pages/receipt_page.dart';
import '../models/payment_phase.dart';
import '../models/payment_state.dart';
import '../models/test_payment_result.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_processing_timeline.dart';
import '../widgets/payment_success_view.dart';

/// Same pacing as the real flow's `PaymentStatusPage` — see that constant's
/// header comment for why this is a UI/UX-only delay.
const _successScreenDuration = Duration(milliseconds: 1400);

/// Development-only counterpart to `PaymentStatusPage` — simulates a
/// successful payment completely offline (see docs/22_DEVELOPMENT_ROADMAP.md
/// Phase 4.5), then lands on the same [ReceiptPage] the real flow uses.
/// Pushed only from the "🧪 Test Payment" button on the Payment Summary
/// dialog; the real Checkout path (`PaymentStatusPage`) is untouched.
class TestPaymentStatusPage extends ConsumerStatefulWidget {
  const TestPaymentStatusPage({
    required this.uid,
    required this.merchantName,
    required this.storeName,
    required this.receiptItems,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.onDone,
    this.customerName,
    this.customerPhone,
    super.key,
  });

  final String uid;
  final String merchantName;
  final String storeName;

  /// Same cart snapshot the real flow's Receipt would show — a test payment
  /// never talks to a backend, so there is no re-priced response to use
  /// instead (see [TestPaymentRepository]'s header comment).
  final List<ReceiptLineItem> receiptItems;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double grandTotal;

  /// Optional walk-in-customer info from Billing's Customer Details step —
  /// see `CustomerDetails`'s own header comment.
  final String? customerName;
  final String? customerPhone;

  final VoidCallback onDone;

  @override
  ConsumerState<TestPaymentStatusPage> createState() =>
      _TestPaymentStatusPageState();
}

class _TestPaymentStatusPageState extends ConsumerState<TestPaymentStatusPage> {
  /// Same "captured once" pattern as `PaymentStatusPage._succeededAt`.
  DateTime? _succeededAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testPaymentControllerProvider(widget.uid).notifier).run();
    });
  }

  void _navigateToReceipt(PaymentState state) {
    final notifier =
        ref.read(testPaymentControllerProvider(widget.uid).notifier);
    final result = notifier.result;
    final receipt = ReceiptModel(
      merchantName: widget.merchantName,
      storeName: widget.storeName,
      orderId: state.orderId ?? result?.reference ?? '—',
      paymentId: state.paymentId,
      transactionId: state.transactionId,
      completedAt: _succeededAt ?? result?.timestamp ?? DateTime.now(),
      items: widget.receiptItems,
      subtotal: widget.subtotal,
      discountTotal: widget.discountTotal,
      taxTotal: widget.taxTotal,
      total: widget.grandTotal,
      paymentMethod: state.paymentMethod ?? TestPaymentResult.method,
      paymentStatus: 'Successful',
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          uid: widget.uid,
          receipt: receipt,
          onNewSale: widget.onDone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(testPaymentControllerProvider(widget.uid),
        (previous, next) {
      final justSucceeded = next.phase == PaymentPhase.paymentSuccessful &&
          previous?.phase != PaymentPhase.paymentSuccessful;
      if (justSucceeded) {
        _succeededAt ??= DateTime.now();
        Future.delayed(_successScreenDuration, () {
          if (mounted) _navigateToReceipt(next);
        });
      }
    });

    final state = ref.watch(testPaymentControllerProvider(widget.uid));

    return PopScope(
      canPop: state.phase.isTerminal,
      child: Scaffold(
        appBar: const AppTopBar(
          title: 'Test Payment',
          actions: [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: StatusChip(label: 'DEV', tone: StatusTone.warning),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: state.phase == PaymentPhase.paymentSuccessful
                        ? PaymentSuccessView(
                            amount: widget.grandTotal,
                            reference: state.paymentId ?? state.orderId,
                            transactionId: state.transactionId,
                            merchantName: widget.merchantName,
                            completedAt: _succeededAt ?? DateTime.now(),
                          )
                        : Column(
                            children: [
                              const SizedBox(height: AppSpacing.md),
                              PaymentProcessingTimeline(phase: state.phase),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                '\$${widget.grandTotal.toStringAsFixed(2)}',
                                style: AppTypography.headingSM
                                    .copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
