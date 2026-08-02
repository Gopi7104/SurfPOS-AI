import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/receipt/models/paired_printer_model.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_line_item.dart';
import 'package:surfpos_ai/features/receipt/models/receipt_model.dart';
import 'package:surfpos_ai/features/receipt/pages/receipt_page.dart';
import 'package:surfpos_ai/features/receipt/providers/receipt_providers.dart';
import 'package:surfpos_ai/features/receipt/repositories/receipt_repository.dart';

import '../../merchant/presentation/screens/test_surface.dart';
import '../fakes/fake_receipt_repository.dart';

final _receipt = ReceiptModel(
  merchantName: 'Acme Surf Co',
  storeName: 'Downtown',
  orderId: 'order-1',
  paymentId: 'pay-1',
  transactionId: 'txn-1',
  completedAt: DateTime(2026, 1, 1, 12, 30),
  items: const [
    ReceiptLineItem(
        productName: 'Widget', quantity: 2, unitPrice: 10, lineTotal: 20),
  ],
  subtotal: 20,
  discountTotal: 0,
  taxTotal: 2,
  total: 22,
  paymentMethod: 'CARD',
  paymentStatus: 'Successful',
);

Widget _wrap(ReceiptRepository repository, {required VoidCallback onNewSale}) {
  return ProviderScope(
    overrides: [receiptRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      home: ReceiptPage(uid: 'uid-1', receipt: _receipt, onNewSale: onNewSale),
    ),
  );
}

void main() {
  testWidgets(
      'shows the sale details and "No printer connected" when nothing is paired',
      (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        FakeReceiptRepository(pairedPrinters: () async => const []),
        onNewSale: () {},
      ),
    );

    await tester.pump(); // post-frame callback fires checkPrinterAndAutoPrint
    await tester.pump(); // resolve pairedPrinters()'s Future

    expect(find.text('Acme Surf Co'), findsOneWidget);
    // Order ID, Reference, and the barcode placeholder's caption all show
    // the same order id — see `ReceiptSummaryCard`'s header comment.
    expect(find.text('order-1'), findsWidgets);
    expect(find.text('pay-1'), findsOneWidget); // Approval Code
    expect(find.text('txn-1'), findsOneWidget);
    expect(find.text('No printer connected'), findsOneWidget);
    expect(find.text('Connect Printer'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('auto-prints when a printer is already paired', (tester) async {
    useTallTestSurface(tester);
    var printed = false;
    await tester.pumpWidget(
      _wrap(
        FakeReceiptRepository(
          pairedPrinters: () async => const [
            PairedPrinterModel(name: 'Front Counter', macAddress: 'AA:BB')
          ],
          connect: (mac) async => true,
          printReceipt: (receipt) async => printed = true,
        ),
        onNewSale: () {},
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(printed, isTrue);
    expect(find.text('Receipt printed.'), findsOneWidget);
  });

  testWidgets('New Sale invokes onNewSale', (tester) async {
    useTallTestSurface(tester);
    var newSale = false;
    await tester.pumpWidget(
      _wrap(
        FakeReceiptRepository(pairedPrinters: () async => const []),
        onNewSale: () => newSale = true,
      ),
    );

    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('New Sale'));
    expect(newSale, isTrue);
  });

  testWidgets('Skip dismisses the no-printer prompt', (tester) async {
    useTallTestSurface(tester);
    await tester.pumpWidget(
      _wrap(
        FakeReceiptRepository(pairedPrinters: () async => const []),
        onNewSale: () {},
      ),
    );

    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(find.text('No printer connected'), findsOneWidget);
  });
}
