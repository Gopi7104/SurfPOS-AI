import 'dart:typed_data';

import '../models/paired_printer_model.dart';
import '../models/receipt_model.dart';

/// Everything the Receipt screen needs from the outside world — PDF
/// generation/sharing and Bluetooth ESC/POS thermal printing — behind one
/// seam so `ReceiptController` never touches `pdf`/`share_plus`/
/// `print_bluetooth_thermal` directly (same Repository/Controller split
/// every other feature in this app follows).
abstract class ReceiptRepository {
  /// Android: every Bluetooth device bonded to this phone. iOS: nearby
  /// devices (see `print_bluetooth_thermal`'s own doc comment) — either way,
  /// this is what "a Bluetooth printer is already paired" is checked
  /// against.
  Future<List<PairedPrinterModel>> pairedPrinters();

  Future<bool> connect(String macAddress);

  Future<bool> isConnected();

  /// Builds the ESC/POS byte sequence for [receipt] and writes it to the
  /// currently connected printer — throws if nothing is connected, so
  /// callers must [connect] first.
  Future<void> printReceipt(ReceiptModel receipt);

  Future<Uint8List> buildReceiptPdf(ReceiptModel receipt);

  /// Hands [pdfBytes] to the OS share sheet (see
  /// `ReceiptRepositoryImpl`'s header comment for why Share PDF/WhatsApp/
  /// Email all resolve to this one mechanism).
  Future<void> shareReceiptPdf(
    Uint8List pdfBytes, {
    required String fileName,
    String? text,
    String? subject,
  });
}
