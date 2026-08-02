import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/printer_status.dart';
import '../models/receipt_action_state.dart';
import '../models/receipt_model.dart';
import '../providers/receipt_providers.dart';

/// Receipt-screen state for exactly one Firebase uid — same cross-user
/// isolation pattern every controller in this app follows (see
/// `PaymentController`'s header comment). Owns printer detection/printing
/// and PDF share hand-off; the Receipt itself ([ReceiptModel]) is built
/// once by the caller and passed in, not owned by this controller.
class ReceiptController
    extends AutoDisposeFamilyNotifier<ReceiptActionState, String> {
  @override
  ReceiptActionState build(String uid) => const ReceiptActionState();

  /// Checks for an already-paired printer and, if one is found, prints
  /// immediately — the spec's "if a Bluetooth printer is already paired,
  /// print automatically". Call once when the Receipt screen first loads.
  Future<void> checkPrinterAndAutoPrint(ReceiptModel receipt) async {
    state = state.copyWith(printerStatus: PrinterStatus.checking);
    try {
      final repository = ref.read(receiptRepositoryProvider);
      final printers = await repository.pairedPrinters();
      if (printers.isEmpty) {
        state = state.copyWith(
            printerStatus: PrinterStatus.notConnected,
            pairedPrinters: printers);
        return;
      }

      final connected = await repository.connect(printers.first.macAddress);
      if (!connected) {
        state = state.copyWith(
            printerStatus: PrinterStatus.notConnected,
            pairedPrinters: printers);
        return;
      }

      state = state.copyWith(
          printerStatus: PrinterStatus.connected, pairedPrinters: printers);
      await printReceipt(receipt);
    } catch (error) {
      state = state.copyWith(
        printerStatus: PrinterStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  /// Lists paired printers for the "Connect Printer" picker, without
  /// connecting to any of them yet.
  Future<void> listPrinters() async {
    state = state.copyWith(printerStatus: PrinterStatus.checking);
    try {
      final printers =
          await ref.read(receiptRepositoryProvider).pairedPrinters();
      state = state.copyWith(
        printerStatus:
            printers.isEmpty ? PrinterStatus.notConnected : state.printerStatus,
        pairedPrinters: printers,
      );
    } catch (error) {
      state = state.copyWith(
          printerStatus: PrinterStatus.error, errorMessage: error.toString());
    }
  }

  Future<void> connectAndPrint(String macAddress, ReceiptModel receipt) async {
    state = state.copyWith(printerStatus: PrinterStatus.checking);
    try {
      final connected =
          await ref.read(receiptRepositoryProvider).connect(macAddress);
      if (!connected) {
        state = state.copyWith(printerStatus: PrinterStatus.notConnected);
        return;
      }
      state = state.copyWith(printerStatus: PrinterStatus.connected);
      await printReceipt(receipt);
    } catch (error) {
      state = state.copyWith(
          printerStatus: PrinterStatus.error, errorMessage: error.toString());
    }
  }

  /// Dismisses the "No printer connected" prompt without printing — the
  /// spec's "Skip" action.
  void skipPrinting() {
    state = state.copyWith(printerStatus: PrinterStatus.notConnected);
  }

  Future<void> printReceipt(ReceiptModel receipt) async {
    state = state.copyWith(
        printerStatus: PrinterStatus.printing, clearErrorMessage: true);
    try {
      await ref.read(receiptRepositoryProvider).printReceipt(receipt);
      state = state.copyWith(printerStatus: PrinterStatus.printed);
    } catch (error) {
      state = state.copyWith(
        printerStatus: PrinterStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> sharePdf(ReceiptModel receipt) async {
    await _share(receipt, subject: 'Receipt — ${receipt.orderId}');
  }

  Future<void> shareViaWhatsApp(ReceiptModel receipt) async {
    await _share(receipt,
        text: 'Here is your receipt from ${receipt.merchantName}.');
  }

  Future<void> shareViaEmail(ReceiptModel receipt) async {
    await _share(
      receipt,
      subject: 'Your receipt from ${receipt.merchantName}',
      text: 'Please find your receipt attached.',
    );
  }

  Future<void> _share(ReceiptModel receipt,
      {String? subject, String? text}) async {
    state = state.copyWith(isSharing: true, clearErrorMessage: true);
    try {
      final repository = ref.read(receiptRepositoryProvider);
      final pdfBytes = await repository.buildReceiptPdf(receipt);
      await repository.shareReceiptPdf(
        pdfBytes,
        fileName: 'receipt-${receipt.orderId}.pdf',
        subject: subject,
        text: text,
      );
      state = state.copyWith(isSharing: false);
    } catch (error) {
      state = state.copyWith(isSharing: false, errorMessage: error.toString());
    }
  }
}
