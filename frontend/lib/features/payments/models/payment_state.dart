import 'payment_phase.dart';

/// [PaymentController]'s state — the checkout attempt currently in flight
/// (or its terminal result), for exactly one Firebase uid.
class PaymentState {
  const PaymentState({
    this.phase = PaymentPhase.creatingPayment,
    this.orderId,
    this.storeId,
    this.paymentId,
    this.transactionId,
    this.amount,
    this.subtotal,
    this.discountTotal,
    this.taxTotal,
    this.paymentMethod,
    this.paymentUrl,
    this.errorMessage,
    this.failureReason,
  });

  final PaymentPhase phase;
  final String? orderId;
  final String? storeId;
  final String? paymentId;
  final String? transactionId;
  final double? amount;

  /// Order-level breakdown from `CheckoutResultModel` (create-checkout
  /// response only — see its header comment) — carried here purely so the
  /// Receipt screen can show a full Products/Tax/Discount/Total breakdown
  /// without re-deriving it from the cart after Checkout has moved on.
  final double? subtotal;
  final double? discountTotal;
  final double? taxTotal;
  final String? paymentMethod;
  final String? paymentUrl;

  /// Set when [phase] is `error` — a network/backend failure creating,
  /// retrying, or polling the payment (never a Surfboard decline, see
  /// [failureReason] for that).
  final String? errorMessage;

  /// Set when [phase] is `declined` — Surfboard's own reason for the
  /// payment failing (see `OrderStatusModel.failureReason`), shown verbatim
  /// per the spec's "Display Surfboard message" requirement.
  final String? failureReason;

  PaymentState copyWith({
    PaymentPhase? phase,
    String? orderId,
    String? storeId,
    String? paymentId,
    String? transactionId,
    double? amount,
    double? subtotal,
    double? discountTotal,
    double? taxTotal,
    String? paymentMethod,
    String? paymentUrl,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? failureReason,
    bool clearFailureReason = false,
  }) {
    return PaymentState(
      phase: phase ?? this.phase,
      orderId: orderId ?? this.orderId,
      storeId: storeId ?? this.storeId,
      paymentId: paymentId ?? this.paymentId,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      subtotal: subtotal ?? this.subtotal,
      discountTotal: discountTotal ?? this.discountTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      failureReason:
          clearFailureReason ? null : (failureReason ?? this.failureReason),
    );
  }
}
