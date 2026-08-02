import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../receipt/models/receipt_model.dart';
import '../../receipt/pages/receipt_page.dart';
import '../widgets/payment_success_view.dart';

/// Full-screen stop between [PaymentStatusPage] and [ReceiptPage] — shows the
/// same checkmark/amount/reference success visual as its own page and waits
/// for the cashier to tap "View Receipt" rather than auto-advancing.
class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    required this.amount,
    required this.reference,
    required this.transactionId,
    required this.merchantName,
    required this.completedAt,
    required this.uid,
    required this.receipt,
    required this.onNewSale,
    super.key,
  });

  final double? amount;
  final String? reference;
  final String? transactionId;
  final String merchantName;
  final DateTime completedAt;

  final String uid;
  final ReceiptModel receipt;
  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const AppTopBar(title: 'Payment'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: PaymentSuccessView(
                      amount: amount,
                      reference: reference,
                      transactionId: transactionId,
                      merchantName: merchantName,
                      completedAt: completedAt,
                    ),
                  ),
                ),
                AppPrimaryButton(
                  label: 'View Receipt',
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ReceiptPage(
                        uid: uid,
                        receipt: receipt,
                        onNewSale: onNewSale,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
