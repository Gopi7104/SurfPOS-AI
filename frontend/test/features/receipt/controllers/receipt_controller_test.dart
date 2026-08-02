import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/receipt/models/paired_printer_model.dart';
import 'package:surfpos_ai/features/receipt/models/printer_status.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_line_item.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_model.dart';
import 'package:surfpos_ai/features/receipt/providers/receipt_providers.dart';
import 'package:surfpos_ai/features/receipt/repositories/receipt_repository.dart';

import '../fakes/fake_receipt_repository.dart';

const _uidA = 'uid-a';
const _uidB = 'uid-b';

final _receipt = ReceiptModel(
  merchantName: 'Acme Surf Co',
  storeName: 'Downtown',
  orderId: 'order-1',
  paymentId: 'pay-1',
  transactionId: 'txn-1',
  completedAt: DateTime(2026, 1, 1),
  items: const [
    ReceiptLineItem(
        productName: 'Widget', quantity: 1, unitPrice: 10, lineTotal: 10),
  ],
  subtotal: 10,
  discountTotal: 0,
  taxTotal: 0,
  total: 10,
  paymentMethod: 'CARD',
  paymentStatus: 'Successful',
);

ProviderContainer _makeContainer(ReceiptRepository repository) {
  return ProviderContainer(
      overrides: [receiptRepositoryProvider.overrideWithValue(repository)]);
}

void main() {
  group('ReceiptController', () {
    test('build() starts with an unknown printer status', () {
      final container = _makeContainer(FakeReceiptRepository());
      addTearDown(container.dispose);

      final state = container.read(receiptControllerProvider(_uidA));

      expect(state.printerStatus, PrinterStatus.unknown);
      expect(state.pairedPrinters, isEmpty);
    });

    test(
        'checkPrinterAndAutoPrint() connects and prints automatically when a printer is already paired',
        () async {
      String? connectedTo;
      var printed = false;
      final container = _makeContainer(FakeReceiptRepository(
        pairedPrinters: () async => const [
          PairedPrinterModel(name: 'Front Counter', macAddress: 'AA:BB')
        ],
        connect: (mac) async {
          connectedTo = mac;
          return true;
        },
        printReceipt: (receipt) async => printed = true,
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .checkPrinterAndAutoPrint(_receipt);

      expect(connectedTo, 'AA:BB');
      expect(printed, isTrue);
      final state = container.read(receiptControllerProvider(_uidA));
      expect(state.printerStatus, PrinterStatus.printed);
    });

    test(
        'checkPrinterAndAutoPrint() shows notConnected when no printer is paired',
        () async {
      final container = _makeContainer(FakeReceiptRepository(
        pairedPrinters: () async => const [],
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .checkPrinterAndAutoPrint(_receipt);

      expect(container.read(receiptControllerProvider(_uidA)).printerStatus,
          PrinterStatus.notConnected);
    });

    test(
        'checkPrinterAndAutoPrint() surfaces a repository failure as the error status',
        () async {
      final container = _makeContainer(FakeReceiptRepository(
        pairedPrinters: () async => throw Exception('bluetooth unavailable'),
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .checkPrinterAndAutoPrint(_receipt);

      final state = container.read(receiptControllerProvider(_uidA));
      expect(state.printerStatus, PrinterStatus.error);
      expect(state.errorMessage, isNotNull);
    });

    test('skipPrinting() moves straight to notConnected', () {
      final container = _makeContainer(FakeReceiptRepository());
      addTearDown(container.dispose);

      container.read(receiptControllerProvider(_uidA).notifier).skipPrinting();

      expect(container.read(receiptControllerProvider(_uidA)).printerStatus,
          PrinterStatus.notConnected);
    });

    test('connectAndPrint() connects to the chosen printer and prints',
        () async {
      var printed = false;
      final container = _makeContainer(FakeReceiptRepository(
        connect: (mac) async => true,
        printReceipt: (receipt) async => printed = true,
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .connectAndPrint('AA:BB', _receipt);

      expect(printed, isTrue);
      expect(container.read(receiptControllerProvider(_uidA)).printerStatus,
          PrinterStatus.printed);
    });

    test('sharePdf() builds the PDF and hands it to the share sheet', () async {
      String? capturedFileName;
      String? capturedSubject;
      final container = _makeContainer(FakeReceiptRepository(
        shareReceiptPdf: (bytes, {required fileName, text, subject}) async {
          capturedFileName = fileName;
          capturedSubject = subject;
        },
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .sharePdf(_receipt);

      expect(capturedFileName, 'receipt-order-1.pdf');
      expect(capturedSubject, contains('order-1'));
      expect(
          container.read(receiptControllerProvider(_uidA)).isSharing, isFalse);
    });

    test('shareViaWhatsApp() shares with WhatsApp-oriented text', () async {
      String? capturedText;
      final container = _makeContainer(FakeReceiptRepository(
        shareReceiptPdf: (bytes, {required fileName, text, subject}) async {
          capturedText = text;
        },
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .shareViaWhatsApp(_receipt);

      expect(capturedText, contains('Acme Surf Co'));
    });

    test('shareViaEmail() shares with an email subject and body', () async {
      String? capturedSubject;
      String? capturedText;
      final container = _makeContainer(FakeReceiptRepository(
        shareReceiptPdf: (bytes, {required fileName, text, subject}) async {
          capturedSubject = subject;
          capturedText = text;
        },
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .shareViaEmail(_receipt);

      expect(capturedSubject, contains('Acme Surf Co'));
      expect(capturedText, isNotNull);
    });

    test('a sharing failure is surfaced without leaving isSharing stuck true',
        () async {
      final container = _makeContainer(FakeReceiptRepository(
        buildReceiptPdf: (receipt) async => throw Exception('pdf failed'),
      ));
      addTearDown(container.dispose);

      await container
          .read(receiptControllerProvider(_uidA).notifier)
          .sharePdf(_receipt);

      final state = container.read(receiptControllerProvider(_uidA));
      expect(state.isSharing, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('two different uids never share printer/sharing state', () async {
      final containerA = _makeContainer(FakeReceiptRepository());
      addTearDown(containerA.dispose);
      final containerB = _makeContainer(FakeReceiptRepository());
      addTearDown(containerB.dispose);

      containerA.read(receiptControllerProvider(_uidA).notifier).skipPrinting();

      expect(containerA.read(receiptControllerProvider(_uidA)).printerStatus,
          PrinterStatus.notConnected);
      expect(containerB.read(receiptControllerProvider(_uidB)).printerStatus,
          PrinterStatus.unknown);
    });
  });
}
