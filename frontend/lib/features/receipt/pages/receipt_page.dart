import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/animations/fade_slide_in.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../controllers/receipt_controller.dart';
import '../models/paired_printer_model.dart';
import '../models/printer_status.dart';
import '../models/receipt_model.dart';
import '../providers/receipt_providers.dart';
import '../widgets/printer_status_banner.dart';
import '../widgets/receipt_action_grid.dart';
import '../widgets/receipt_summary_card.dart';

/// The screen Checkout lands on right after `PaymentPhase.paymentSuccessful`
/// — displays the completed sale and offers Print/Share/New Sale actions.
/// See docs/22_DEVELOPMENT_ROADMAP.md, Phase 5.
class ReceiptPage extends ConsumerStatefulWidget {
  const ReceiptPage({
    required this.uid,
    required this.receipt,
    required this.onNewSale,
    super.key,
  });

  final String uid;
  final ReceiptModel receipt;

  /// Called when the merchant taps "New Sale" — the caller (BillingPage)
  /// clears the cart and returns to Billing, same contract
  /// `PaymentStatusPage.onDone` already had.
  final VoidCallback onNewSale;

  @override
  ConsumerState<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends ConsumerState<ReceiptPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(receiptControllerProvider(widget.uid).notifier)
          .checkPrinterAndAutoPrint(widget.receipt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptControllerProvider(widget.uid));
    final notifier = ref.read(receiptControllerProvider(widget.uid).notifier);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const AppTopBar(title: 'Receipt'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        PrinterStatusBanner(
                          status: state.printerStatus,
                          onConnectPrinter: () =>
                              _showPrinterPicker(context, notifier),
                          onSkip: notifier.skipPrinting,
                          onRetryPrint: () =>
                              notifier.printReceipt(widget.receipt),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                            child: ReceiptSummaryCard(receipt: widget.receipt)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ReceiptActionGrid(
                  receipt: widget.receipt,
                  notifier: notifier,
                  isSharing: state.isSharing,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppPrimaryButton(
                    label: 'New Sale', onPressed: widget.onNewSale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrinterPicker(BuildContext context, ReceiptController notifier) {
    notifier.listPrinters();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(receiptControllerProvider(widget.uid));
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Paired Printers',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.printerStatus == PrinterStatus.checking)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.pairedPrinters.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text('No paired Bluetooth printers found.'),
                      )
                    else
                      for (final printer in state.pairedPrinters)
                        _PrinterTile(
                          printer: printer,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            notifier.connectAndPrint(
                                printer.macAddress, widget.receipt);
                          },
                        ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PrinterTile extends StatelessWidget {
  const _PrinterTile({required this.printer, required this.onTap});

  final PairedPrinterModel printer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(LucideIcons.printer),
      title: Text(printer.name),
      subtitle: Text(printer.macAddress),
      onTap: onTap,
    );
  }
}
