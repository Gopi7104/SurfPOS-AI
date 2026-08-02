import '../../payments/models/payment_state.dart';
import 'receipt_line_item.dart';

/// Everything the Receipt screen (and its Print/Share actions) needs —
/// assembled once, right after Checkout reaches `paymentSuccessful`, from
/// data this app already has on-device (the cart + the completed
/// [PaymentState]). There is no backend "get receipt" endpoint — a Sale/
/// order-history persistence layer doesn't exist yet (out of scope for
/// Payment Integration, see `webhook.controller.js`'s header comment), so
/// this is built client-side and never re-fetched.
class ReceiptModel {
  const ReceiptModel({
    required this.merchantName,
    required this.storeName,
    required this.orderId,
    required this.paymentId,
    required this.transactionId,
    required this.completedAt,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.customerName,
    this.customerPhone,
  });

  final String merchantName;
  final String storeName;
  final String orderId;
  final String? paymentId;
  final String? transactionId;
  final DateTime completedAt;
  final List<ReceiptLineItem> items;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final String paymentMethod;
  final String paymentStatus;

  /// Optional walk-in-customer info captured by Billing's Customer Details
  /// step (see `CustomerDetails`'s own header comment) — frontend-only,
  /// shown here purely for the printed/shared receipt; never sent to any
  /// backend.
  final String? customerName;
  final String? customerPhone;

  /// [items] is a snapshot of the cart the merchant checked out with —
  /// Checkout's own request only ever carries `{ productId, quantity }`
  /// (`billing.service.js#resolveCheckoutItems` re-resolves price/tax/
  /// discount server-side), so the caller (BillingPage, the only place with
  /// both the cart and the product catalog) builds these line items rather
  /// than this feature depending on Billing's `CartItemModel` directly.
  /// [state]'s subtotal/discount/tax come from the same checkout response
  /// Billing's own totals were built from, so the two always agree.
  factory ReceiptModel.fromPayment({
    required PaymentState state,
    required String merchantName,
    required String storeName,
    required List<ReceiptLineItem> items,
    required DateTime completedAt,
    String? customerName,
    String? customerPhone,
  }) {
    return ReceiptModel(
      merchantName: merchantName,
      storeName: storeName,
      orderId: state.orderId ?? '—',
      paymentId: state.paymentId,
      transactionId: state.transactionId,
      completedAt: completedAt,
      items: items,
      subtotal: state.subtotal ?? 0,
      discountTotal: state.discountTotal ?? 0,
      taxTotal: state.taxTotal ?? 0,
      total: state.amount ?? 0,
      paymentMethod: state.paymentMethod ?? 'Card',
      paymentStatus: 'Successful',
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }
}
