/// One cart line sent to `POST /payments/checkout` — deliberately just
/// `productId`/`quantity`. Price/tax/discount are never sent: the backend
/// re-resolves them live from Inventory (see
/// `backend/src/modules/billing/billing.service.js`) so a tampered client
/// can never under-pay by forging a lower price.
class CheckoutItem {
  const CheckoutItem({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() =>
      {'productId': productId, 'quantity': quantity};
}
