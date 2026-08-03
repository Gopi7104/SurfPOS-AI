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
import 'thermal_receipt_formatter.dart';

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
///
/// Requests `BLUETOOTH_SCAN` too, not just `BLUETOOTH_CONNECT` — confirmed
/// live (Android 13) that the plugin's native `connect()` unconditionally
/// calls `BluetoothAdapter.cancelDiscovery()` before opening the RFCOMM
/// socket, which itself requires `BLUETOOTH_SCAN` and fails with
/// `connect: false` otherwise, even though this app never scans for new
/// devices itself.
class ReceiptRepositoryImpl implements ReceiptRepository {
  Future<bool> _hasPermission() async {
    if (!Platform.isAndroid) {
      return PrintBluetoothThermal.isPermissionBluetoothGranted;
    }
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  /// A read-only *check* — never a `.request()` — for whether Bluetooth
  /// permission is already granted. `ReceiptController.checkPrinterAndAutoPrint`
  /// runs automatically the instant the Receipt screen mounts, right after a
  /// payment completes — on some OEM Android builds (confirmed on a MIUI
  /// device), a permission dialog triggered by that kind of automatic,
  /// no-direct-user-tap code path never resolves, which is what left the
  /// Receipt screen's "Checking for a paired printer…" spinner stuck forever
  /// until the merchant backed out to Settings' Printer page and connected
  /// from there instead — a real button tap, which the OS is willing to show
  /// a permission dialog for. Checking first and skipping the auto-connect
  /// entirely when permission isn't already granted (see
  /// [ReceiptController.checkPrinterAndAutoPrint]) avoids ever firing that
  /// request from the automatic path; tapping "Connect Printer" still goes
  /// through [connect]/[pairedPrinters]'s own `_hasPermission`, a real
  /// request, from a real tap — exactly the path that already works today.
  @override
  Future<bool> hasBluetoothPermission() async {
    if (!Platform.isAndroid) {
      return PrintBluetoothThermal.isPermissionBluetoothGranted;
    }
    final connectStatus = await Permission.bluetoothConnect.status;
    final scanStatus = await Permission.bluetoothScan.status;
    return connectStatus.isGranted && scanStatus.isGranted;
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

  /// Printable template — premium retail-POS layout (Square/Toast/Shopify
  /// style): compact centered header (merchant/store/tagline + Receipt #/
  /// Txn ID/Date/Time, one line each, never wrapping — long IDs truncate
  /// with `...` instead, see [ThermalReceiptFormatter.printKeyValue]), a
  /// real ITEM/QTY/AMOUNT product table with word-wrapped long names, an
  /// emphasized centered/bold/double-size grand TOTAL, grouped payment
  /// details, and a clean footer. Every section is built via
  /// [ThermalReceiptFormatter] — see that class's header comment for how
  /// it stays width-agnostic (58mm/80mm) without hardcoded spacing.
  ///
  /// Every field printed here already exists on [ReceiptModel] — nothing
  /// invented. Approval/Ref No map the same way the in-app
  /// `ReceiptSummaryCard` labels them (paymentId/orderId respectively, just
  /// under shorter print-friendly labels here).
  /// Deliberately omits a store logo (this app's only logo asset is a
  /// full-color/gradient PNG that would dither poorly on a 1-bit thermal
  /// printer — text-only branding is the safer default) and a QR code
  /// (there's no hosted "digital receipt" page to link to) and any social/
  /// website/support contact line (no such field exists on this model or
  /// anywhere else this repository can reach) — printing any of those
  /// would mean fabricating data this app doesn't actually have.
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
    const paperSize = PaperSize.mm58;
    final generator = Generator(paperSize, profile);
    final f = ThermalReceiptFormatter(generator, paperSize);
    final bytes = <int>[];

    bytes.addAll(f.printHeader(
      merchantName: receipt.merchantName,
      storeName: receipt.storeName,
      receiptNo: receipt.orderId,
      transactionId: receipt.transactionId,
      date: _formatReceiptDate(receipt.completedAt),
      time: _formatReceiptTime(receipt.completedAt),
    ));

    if (receipt.customerName != null || receipt.customerPhone != null) {
      if (receipt.customerName != null) {
        bytes.addAll(f.printKeyValue('Customer', receipt.customerName!));
      }
      if (receipt.customerPhone != null) {
        bytes.addAll(f.printKeyValue('Phone', receipt.customerPhone!));
      }
      bytes.addAll(f.printDivider());
    }

    bytes.addAll(f.printProductTableHeader());
    bytes.addAll(f.printDivider());
    for (final item in receipt.items) {
      if (item.productName.length <= f.singleLineItemChars) {
        bytes.addAll(
            f.printProductRow(item.productName, item.quantity, item.lineTotal));
      } else {
        bytes.addAll(f.printWrappedProduct(
            item.productName, item.quantity, item.lineTotal));
      }
    }
    bytes.addAll(f.printDivider());

    bytes.addAll(f.printTotals(
      subtotal: receipt.subtotal,
      discount: receipt.discountTotal,
      tax: receipt.taxTotal,
      total: receipt.total,
    ));

    bytes.addAll(f.printKeyValue('Payment', receipt.paymentMethod));
    bytes.addAll(f.printKeyValue('Status', receipt.paymentStatus.toUpperCase(),
        boldValue: true));
    bytes.addAll(f.printKeyValue('Ref No', receipt.orderId));
    if (receipt.paymentId != null) {
      bytes.addAll(f.printKeyValue('Approval', receipt.paymentId!));
    }
    bytes.addAll(f.printDivider());

    bytes.addAll(f.printFooter());

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    final written = await PrintBluetoothThermal.writeBytes(bytes);
    if (!written) {
      throw StateError('The printer did not accept the receipt.');
    }
  }

  /// `03 Aug 2026` — the printed template's own date format, distinct from
  /// [_formatDateTime] (still used unchanged by [buildReceiptPdf]/the PDF
  /// share flow, which this redesign doesn't touch).
  String _formatReceiptDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$day ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// `11:13 AM` — the printed template's own time format, same scope note
  /// as [_formatReceiptDate].
  String _formatReceiptTime(DateTime dateTime) {
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
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
