import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:share_plus/share_plus.dart';

import '../models/paired_printer_model.dart';
import '../models/receipt_model.dart';
import 'receipt_repository.dart';

/// Neither WhatsApp nor Gmail/Mail expose a public API to receive a file
/// attachment via a deep link — the OS share sheet (`share_plus`) is the
/// only officially supported hand-off for "send this PDF to app X" on both
/// Android and iOS. So Share PDF, Send via WhatsApp, and Send via Email all
/// call [shareReceiptPdf] — the button just changes the pre-filled
/// text/subject; the merchant still picks the destination app from the
/// sheet Android/iOS themselves present. `ReceiptController` keeps these as
/// three distinct actions per the Phase 5 spec even though they share one
/// mechanism underneath.
///
/// Bluetooth permissions (`BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN` on Android
/// 12+, legacy `BLUETOOTH`/`BLUETOOTH_ADMIN`) come from
/// `print_bluetooth_thermal`'s own bundled AndroidManifest via Android's
/// manifest merger — not duplicated in this app's manifest.
///
/// [PrintBluetoothThermal.isPermissionBluetoothGranted] only *checks*
/// `BLUETOOTH_CONNECT` on Android 12+ — verified against the plugin's own
/// native source, its runtime-request call is dead code, so it can never
/// actually show the OS permission dialog. Without a real request, every
/// other plugin method (`connectionStatus`, `connect`, `writeBytes`) hangs
/// forever when called while permission is missing — the plugin's native
/// side never replies to the platform channel in that case. `_hasPermission`
/// below performs the real request (via `permission_handler`) and every
/// method calls it first so none of them can reach that hang.
class ReceiptRepositoryImpl implements ReceiptRepository {
  Future<bool> _hasPermission() async {
    if (!Platform.isAndroid) {
      return PrintBluetoothThermal.isPermissionBluetoothGranted;
    }
    final status = await Permission.bluetoothConnect.request();
    return status.isGranted;
  }

  @override
  Future<List<PairedPrinterModel>> pairedPrinters() async {
    if (!await _hasPermission()) return [];

    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return [
      for (final device in devices)
        PairedPrinterModel(name: device.name, macAddress: device.macAdress),
    ];
  }

  @override
  Future<bool> connect(String macAddress) async {
    if (!await _hasPermission()) return false;
    return PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  @override
  Future<bool> isConnected() async {
    if (!await _hasPermission()) return false;
    return PrintBluetoothThermal.connectionStatus;
  }

  @override
  Future<void> printReceipt(ReceiptModel receipt) async {
    if (!await _hasPermission()) {
      throw StateError('Bluetooth permission is required to use a printer.');
    }
    final connected = await isConnected();
    if (!connected) {
      throw StateError('No printer connected.');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(
      receipt.merchantName,
      styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(receipt.storeName,
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Order: ${receipt.orderId}'));
    if (receipt.paymentId != null) {
      bytes.addAll(generator.text('Payment: ${receipt.paymentId}'));
    }
    if (receipt.transactionId != null) {
      bytes.addAll(generator.text('Txn: ${receipt.transactionId}'));
    }
    bytes.addAll(generator.text(_formatDateTime(receipt.completedAt)));
    bytes.addAll(generator.hr());

    for (final item in receipt.items) {
      bytes.addAll(generator.row([
        PosColumn(text: '${item.quantity}x ${item.productName}', width: 8),
        PosColumn(
            text: item.lineTotal.toStringAsFixed(2),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    bytes.addAll(generator.hr());
    bytes.addAll(_totalRow(generator, 'Subtotal', receipt.subtotal));
    bytes.addAll(_totalRow(generator, 'Discount', -receipt.discountTotal));
    bytes.addAll(_totalRow(generator, 'Tax', receipt.taxTotal));
    bytes.addAll(_totalRow(generator, 'Total', receipt.total, bold: true));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Payment Method: ${receipt.paymentMethod}'));
    bytes.addAll(generator.text('Status: ${receipt.paymentStatus}'));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    final written = await PrintBluetoothThermal.writeBytes(bytes);
    if (!written) {
      throw StateError('The printer did not accept the receipt.');
    }
  }

  List<int> _totalRow(Generator generator, String label, double amount,
      {bool bold = false}) {
    return generator.row([
      PosColumn(text: label, width: 8, styles: PosStyles(bold: bold)),
      PosColumn(
          text: amount.toStringAsFixed(2),
          width: 4,
          styles: PosStyles(align: PosAlign.right, bold: bold)),
    ]);
  }

  @override
  Future<Uint8List> buildReceiptPdf(ReceiptModel receipt) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(receipt.merchantName,
                style: const pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.Text(receipt.storeName, textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 12),
            pw.Divider(),
            _kv('Order ID', receipt.orderId),
            if (receipt.paymentId != null)
              _kv('Payment ID', receipt.paymentId!),
            if (receipt.transactionId != null)
              _kv('Transaction ID', receipt.transactionId!),
            _kv('Date & Time', _formatDateTime(receipt.completedAt)),
            _kv('Payment Method', receipt.paymentMethod),
            _kv('Payment Status', receipt.paymentStatus),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const ['Product', 'Qty', 'Unit Price', 'Line Total'],
              data: [
                for (final item in receipt.items)
                  [
                    item.productName,
                    item.quantity.toString(),
                    item.unitPrice.toStringAsFixed(2),
                    item.lineTotal.toStringAsFixed(2),
                  ],
              ],
            ),
            pw.SizedBox(height: 12),
            _kv('Subtotal', receipt.subtotal.toStringAsFixed(2)),
            _kv('Discount', '-${receipt.discountTotal.toStringAsFixed(2)}'),
            _kv('Tax', receipt.taxTotal.toStringAsFixed(2)),
            pw.Divider(),
            _kv('Total', receipt.total.toStringAsFixed(2), bold: true),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _kv(String label, String value, {bool bold = false}) {
    final style = bold
        ? const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)
        : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Future<void> shareReceiptPdf(
    Uint8List pdfBytes, {
    required String fileName,
    String? text,
    String? subject,
  }) async {
    final file =
        XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf');
    await SharePlus.instance.share(
      ShareParams(files: [file], text: text, subject: subject),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }
}
