import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../customers/models/customer_draft.dart';
import '../../customers/models/customer_query.dart';
import '../../customers/providers/customer_providers.dart';
import '../../customers/repositories/customer_repository.dart';
import '../../receipt/models/receipt_line_item.dart';
import '../../receipt/models/receipt_model.dart';
import '../../receipt/pages/receipt_page.dart';
import '../../reports/models/sales_record.dart';
import '../../reports/providers/reports_providers.dart';
import '../../reports/providers/sales_ledger_providers.dart';
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
    this.customerId,
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

  /// See `PaymentStatusPage.customerId`'s header comment — same Phase
  /// CRM-1 hook, so a test payment against a linked customer also counts
  /// toward their stats/points (useful for trying the CRM flow without a
  /// real Surfboard transaction).
  final String? customerId;

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

  /// Phase CRM-2: mirrors `PaymentStatusPage._recordCustomerPurchase`'s
  /// auto-resolve behavior — a typed name/phone still gets linked/created
  /// even when the Customer Details step never matched/created one.
  Future<void> _recordCustomerPurchase(DateTime completedAt) async {
    try {
      final repository = ref.read(customerRepositoryProvider(widget.uid));
      final customerId = await _resolveCustomerId(repository);
      if (customerId == null) return;

      await repository.recordPurchase(
        customerId,
        amount: widget.grandTotal,
        itemNames: widget.receiptItems.map((item) => item.productName).toList(),
        paymentMethod: TestPaymentResult.method,
        purchasedAt: completedAt,
      );
      ref.invalidate(customerStatsProvider(widget.uid));
      ref.invalidate(customerListControllerProvider(widget.uid));
    } catch (_) {
      // Best-effort — see `PaymentStatusPage._recordCustomerPurchase`.
    }
  }

  /// See `PaymentStatusPage._resolveCustomerId`'s own header comment —
  /// identical resolution logic, duplicated rather than shared since
  /// these two pages already independently duplicate their whole
  /// success-hook shape (see this class's header comment).
  Future<String?> _resolveCustomerId(CustomerRepository repository) async {
    if (widget.customerId != null) return widget.customerId;

    final phone = widget.customerPhone?.trim();
    if (phone == null || phone.isEmpty) return null;

    final matches =
        await repository.listCustomers(CustomerQuery(search: phone), limit: 1);
    if (matches.items.isNotEmpty) return matches.items.first.id;

    final typedName = widget.customerName?.trim() ?? '';
    final nameParts =
        typedName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Walk-in';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Customer';

    final created = await repository.createCustomer(
        CustomerDraft(firstName: firstName, lastName: lastName, phone: phone));
    return created.id;
  }

  /// See `PaymentStatusPage._recordSale`'s own header comment.
  Future<void> _recordSale(DateTime completedAt) async {
    try {
      final record = SalesRecord(
        id: completedAt.toIso8601String(),
        receiptNumber: ref
                .read(testPaymentControllerProvider(widget.uid).notifier)
                .result
                ?.reference ??
            '—',
        occurredAt: completedAt,
        total: widget.grandTotal,
        paymentMethod: TestPaymentResult.method,
        customerId: widget.customerId,
        customerName: widget.customerName,
        items: [
          for (final item in widget.receiptItems)
            SalesRecordItem(
              productId: item.productId,
              name: item.productName,
              category: item.category,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              lineTotal: item.lineTotal,
            ),
        ],
      );
      await ref
          .read(salesLedgerRepositoryProvider(widget.uid))
          .recordSale(record);
      ref.invalidate(salesLedgerRecordsProvider(widget.uid));
      ref.invalidate(salesLedgerSnapshotProvider(widget.uid));
      ref.invalidate(reportsControllerProvider(widget.uid));
    } catch (_) {
      // Best-effort — see `PaymentStatusPage._recordSale`.
    }
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
        _recordSale(_succeededAt!);
        _recordCustomerPurchase(_succeededAt!);
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
