import 'paired_printer_model.dart';
import 'printer_status.dart';

/// [ReceiptController]'s state — the printer connection/printing status plus
/// the transient busy/error flags the Receipt screen's action buttons
/// (Print/Share/WhatsApp/Email) render around.
class ReceiptActionState {
  const ReceiptActionState({
    this.printerStatus = PrinterStatus.unknown,
    this.pairedPrinters = const [],
    this.isSharing = false,
    this.errorMessage,
  });

  final PrinterStatus printerStatus;

  /// Populated once the merchant taps "Connect Printer" and this app lists
  /// the phone's paired Bluetooth devices to choose from.
  final List<PairedPrinterModel> pairedPrinters;

  /// True while generating/handing off the PDF for Share/WhatsApp/Email —
  /// distinct from [printerStatus] since sharing and printing are
  /// independent actions the merchant can trigger in either order.
  final bool isSharing;

  final String? errorMessage;

  ReceiptActionState copyWith({
    PrinterStatus? printerStatus,
    List<PairedPrinterModel>? pairedPrinters,
    bool? isSharing,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ReceiptActionState(
      printerStatus: printerStatus ?? this.printerStatus,
      pairedPrinters: pairedPrinters ?? this.pairedPrinters,
      isSharing: isSharing ?? this.isSharing,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
