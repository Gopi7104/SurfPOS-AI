import '../models/paired_printer_info.dart';
import '../models/printer_config.dart';

/// Seam for the Printer section's device management — pairing, connecting,
/// and a test print, independent of the Receipt feature's own printing
/// (see [PrinterRepositoryImpl]'s header comment for why this doesn't
/// depend on `ReceiptRepository`).
abstract class PrinterRepository {
  Future<List<PairedPrinterInfo>> pairedPrinters();

  Future<bool> connect(String macAddress);

  Future<bool> isConnected();

  /// Prints a short ESC/POS test slip at [paperSize] — throws if nothing
  /// is connected.
  Future<void> testPrint(PrinterPaperSize paperSize);
}
