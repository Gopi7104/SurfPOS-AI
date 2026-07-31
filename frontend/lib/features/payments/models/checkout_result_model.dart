/// Mirrors the `checkout` object returned by `POST /payments/checkout` and
/// `POST /payments/checkout/:orderId/retry` (see
/// `backend/src/modules/payments/payment.service.js#createCheckout`/
/// `#retryPayment`). `subtotal`/`discountTotal`/`taxTotal`/`amount` are only
/// present on the initial create response — a retry reuses the same order,
/// so the caller already has those from the original [CheckoutResultModel].
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
