import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/branding/surfboard_logo.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../models/receipt_model.dart';

/// The full Receipt breakdown, styled to resemble a real retail till
/// receipt — logo, merchant/store, transaction identifiers, itemized lines,
/// totals, and a barcode/QR placeholder. Deliberately shows only fields
/// [ReceiptModel] actually carries — no store address (not part of this
/// model) and no invented fee lines.
class ReceiptSummaryCard extends StatelessWidget {
  const ReceiptSummaryCard({required this.receipt, super.key});

  final ReceiptModel receipt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: SurfboardLogo.badge(size: 52)),
          const SizedBox(height: AppSpacing.sm),
          Text(receipt.merchantName,
              style: AppTypography.headingSM, textAlign: TextAlign.center),
          Text(receipt.storeName,
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          _row('Order ID', receipt.orderId),
          _row('Date & Time', _formatDateTime(receipt.completedAt)),
          if (receipt.customerName != null || receipt.customerPhone != null)
            _row(
              'Customer',
              [
                if (receipt.customerName != null) receipt.customerName!,
                if (receipt.customerPhone != null) receipt.customerPhone!,
              ].join(' · '),
            ),
          const SizedBox(height: AppSpacing.md),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('Item',
                      style: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w700))),
              Expanded(
                  child: Text('Qty',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w700))),
              Expanded(
                  child: Text('Price',
                      textAlign: TextAlign.end,
                      style: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in receipt.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.productName,
                        style: AppTypography.bodyMD,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: Text('${item.quantity}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMD),
                  ),
                  Expanded(
                    child: Text(
                      '\$${item.lineTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: AppTypography.bodyMD
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          _row('Subtotal', '\$${receipt.subtotal.toStringAsFixed(2)}'),
          _row('Discount', '-\$${receipt.discountTotal.toStringAsFixed(2)}'),
          _row('Tax', '\$${receipt.taxTotal.toStringAsFixed(2)}'),
          const SizedBox(height: AppSpacing.xs),
          _row('Total', '\$${receipt.total.toStringAsFixed(2)}', bold: true),
          const SizedBox(height: AppSpacing.md),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          _row('Payment Method', receipt.paymentMethod),
          if (receipt.paymentId != null)
            _row('Approval Code', receipt.paymentId!),
          if (receipt.transactionId != null)
            _row('Transaction ID', receipt.transactionId!),
          _row('Reference', receipt.orderId),
          const SizedBox(height: AppSpacing.lg),
          Text('Thank you for shopping with us!',
              textAlign: TextAlign.center,
              style:
                  AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          Center(child: _BarcodePlaceholder(seed: receipt.orderId)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? AppTypography.bodyMD
            .copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)
        : AppTypography.bodyMD;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold ? style : style.copyWith(color: AppColors.textGrey)),
          Flexible(
            child: Text(value,
                style: style,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedLinePainter(), size: Size.infinite),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

/// A stylized barcode graphic — a visual placeholder only (not a real,
/// scannable encoding of [seed]); a future phase may replace this with an
/// actual barcode/QR of the order reference.
class _BarcodePlaceholder extends StatelessWidget {
  const _BarcodePlaceholder({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 48,
          child: CustomPaint(painter: _BarcodePainter(seed.hashCode)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(seed, style: AppTypography.caption),
      ],
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()..color = AppColors.textDark;
    var x = 0.0;
    while (x < size.width) {
      final barWidth = 1.0 + random.nextInt(3);
      if (random.nextBool()) {
        canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
      }
      x += barWidth + 2;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) =>
      oldDelegate.seed != seed;
}
