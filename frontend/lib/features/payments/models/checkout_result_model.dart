/// Mirrors the `checkout` object returned by `POST /payments/checkout` and
/// `POST /payments/checkout/:orderId/retry` (see
/// `backend/src/modules/payments/payment.service.js#createCheckout`/
/// `#retryPayment`). A retry response carries a brand-new [orderId] — the
/// backend creates a fresh order (and its own fresh hosted payment link)
/// rather than reopening the original order's now-possibly-dead link — so
/// callers must overwrite their cached `orderId` with this one, not keep
/// polling the old one.
class CheckoutResultModel {
  const CheckoutResultModel({
    required this.orderId,
    this.storeId,
    this.subtotal,
    this.discountTotal,
    this.taxTotal,
    this.amount,
    this.paymentId,
    this.paymentUrl,
    this.qr,
    this.qrData,
    this.qrLink,
  });

  final String orderId;
  final String? storeId;
  final double? subtotal;
  final double? discountTotal;
  final double? taxTotal;
  final double? amount;
  final String? paymentId;
  final String? paymentUrl;
  final String? qr;
  final String? qrData;
  final String? qrLink;

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) {
    return CheckoutResultModel(
      orderId: json['orderId'] as String,
      storeId: json['storeId'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      discountTotal: (json['discountTotal'] as num?)?.toDouble(),
      taxTotal: (json['taxTotal'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      paymentId: json['paymentId'] as String?,
      paymentUrl: json['paymentUrl'] as String?,
      qr: json['qr'] as String?,
      qrData: json['qrData'] as String?,
      qrLink: json['qrLink'] as String?,
    );
  }
}
