/// Mirrors the `status` object returned by
/// `GET /payments/checkout/:orderId/status` (see
/// `backend/src/modules/payments/payment.service.js#getCheckoutStatus`,
/// `backend/src/integrations/surfboard/mappers/payment.mapper.js#toOrderStatusDomain`).
///
/// `orderStatus` is one of `PENDING | PAYMENT_COMPLETED | PAYMENT_CANCELLED |
/// PARTIAL_PAYMENT_COMPLETED | PAYMENT_PROCESSED`; `paymentStatus` is one of
/// `PAYMENT_INITIATED | PAYMENT_PROCESSING | PAYMENT_PROCESSED |
/// PAYMENT_COMPLETED | PAYMENT_FAILED | PAYMENT_CANCELLED` — see
/// `PaymentController`'s phase mapping for how these enum strings become a
/// [PaymentPhase].
class OrderStatusModel {
  const OrderStatusModel({
    this.orderStatus,
    this.paymentStatus,
    this.paymentId,
    this.paymentMethod,
    this.amount,
    this.failureReason,
    this.transactionId,
  });

  final String? orderStatus;
  final String? paymentStatus;
  final String? paymentId;
  final String? paymentMethod;
  final double? amount;
  final String? failureReason;
  final String? transactionId;

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      orderStatus: json['orderStatus'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paymentId: json['paymentId'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      failureReason: json['failureReason'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }
}
