import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/billing/models/billing_state.dart';
import 'package:surfpos_ai/features/billing/models/cart_item_model.dart';
import 'package:surfpos_ai/features/payments/widgets/payment_summary_dialog.dart';

import '../../billing/fakes/fake_billing_repository.dart';
import '../../merchant/presentation/screens/test_surface.dart';

Future<void> _pumpDialog(WidgetTester tester,
    {required VoidCallback onConfirm}) async {
  final cart = BillingState(
    items: [
      CartItemModel(
          product:
              testCartProduct(id: 'p1', name: 'Blue Wave Surf Wax', price: 100),
          quantity: 2),
    ],
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PaymentSummaryDialog(
                  cart: cart,
                  merchantName: 'Nordic Surf AB',
                  storeName: 'Stockholm Store',
                  onConfirm: onConfirm,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows merchant, store, products, and totals', (tester) async {
    useTallTestSurface(tester);
    await _pumpDialog(tester, onConfirm: () {});

    expect(find.text('Nordic Surf AB'), findsOneWidget);
    expect(find.text('Stockholm Store'), findsOneWidget);
    expect(find.text('Blue Wave Surf Wax × 2'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.text('Payment Amount'), findsOneWidget);
  });

  testWidgets('Confirm closes the dialog and invokes onConfirm',
      (tester) async {
    useTallTestSurface(tester);
    var confirmed = false;
    await _pumpDialog(tester, onConfirm: () => confirmed = true);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.byType(PaymentSummaryDialog), findsNothing);
  });

  testWidgets('Cancel closes the dialog without invoking onConfirm',
      (tester) async {
    useTallTestSurface(tester);
    var confirmed = false;
    await _pumpDialog(tester, onConfirm: () => confirmed = true);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    expect(find.byType(PaymentSummaryDialog), findsNothing);
  });
}
