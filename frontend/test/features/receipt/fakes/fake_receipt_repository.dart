import 'dart:typed_data';

import 'package:surfpos_ai/features/receipt/models/paired_printer_model.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_model.dart';
import 'package:surfpos_ai/features/receipt/repositories/receipt_repository.dart';

/// Configurable [ReceiptRepository] test double — mirrors
/// `FakePaymentRepository`: every method defaults to a no-op/empty behavior,
/// overridable per test, never touching the real Bluetooth/share plugins
/// (which don't have platform-channel handlers in `flutter test`).
class FakeReceiptRepository implements ReceiptRepository {
  FakeReceiptRepository({
    Future<List<PairedPrinterModel>> Function()? pairedPrinters,
    Future<bool> Function(String macAddress)? connect,
    Future<bool> Function()? isConnected,
    Future<void> Function(ReceiptModel receipt)? printReceipt,
    Future<Uint8List> Function(ReceiptModel receipt)? buildReceiptPdf,
    Future<void> Function(Uint8List pdfBytes,
            {required String fileName, String? text, String? subject})?
        shareReceiptPdf,
  })  : _pairedPrinters = pairedPrinters ?? (() async => const []),
        _connect = connect ?? ((macAddress) async => true),
        _isConnected = isConnected ?? (() async => false),
        _printReceipt = printReceipt ?? ((receipt) async {}),
        _buildReceiptPdf = buildReceiptPdf ?? ((receipt) async => Uint8List(0)),
        _shareReceiptPdf = shareReceiptPdf ??
            ((pdfBytes, {required fileName, text, subject}) async {});

  final Future<List<PairedPrinterModel>> Function() _pairedPrinters;
  final Future<bool> Function(String macAddress) _connect;
  final Future<bool> Function() _isConnected;
  final Future<void> Function(ReceiptModel receipt) _printReceipt;
  final Future<Uint8List> Function(ReceiptModel receipt) _buildReceiptPdf;
  final Future<void> Function(Uint8List pdfBytes,
      {required String fileName,
      String? text,
      String? subject}) _shareReceiptPdf;

  @override
  Future<List<PairedPrinterModel>> pairedPrinters() => _pairedPrinters();

  @override
  Future<bool> connect(String macAddress) => _connect(macAddress);

  @override
  Future<bool> isConnected() => _isConnected();

  @override
  Future<void> printReceipt(ReceiptModel receipt) => _printReceipt(receipt);

  @override
  Future<Uint8List> buildReceiptPdf(ReceiptModel receipt) =>
      _buildReceiptPdf(receipt);

  @override
  Future<void> shareReceiptPdf(
    Uint8List pdfBytes, {
    required String fileName,
    String? text,
    String? subject,
  }) =>
      _shareReceiptPdf(pdfBytes,
          fileName: fileName, text: text, subject: subject);
}
