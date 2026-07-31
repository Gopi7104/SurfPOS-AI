import '../models/checkout_item.dart';
import '../models/checkout_result_model.dart';
import '../models/order_status_model.dart';

/// Seam between [PaymentController] and the backend's `/payments` API — the
/// Flutter app never talks to Surfboard directly, only to this app's own
/// backend (see docs/15_SURFBOARD_INTEGRATION.md § 1). The backend re-
/// resolves every line item's price/tax/discount from Inventory itself
/// (`billing.service.js`), so [createCheckout] only ever sends
/// `{ productId, quantity }` per line — never a price.
///
/// Checkout runs through a Surfboard-hosted **Payment Page** (see
/// `CheckoutResultModel.paymentUrl`) rather than a physical card terminal —
/// this app has never registered/linked any hardware terminal. The customer
/// completes card entry in their own browser (opened via `url_launcher`)
/// while this app polls [getCheckoutStatus] for the result.
abstract class PaymentRepository {
  Future<CheckoutResultModel> createCheckout(
      {String? storeId, required List<CheckoutItem> items});

  /// Re-initiates payment against an existing order — per Surfboard's own
  /// payment lifecycle, a cancelled/failed payment doesn't need a new order.
  Future<CheckoutResultModel> retryPayment(
      {required String orderId, required String storeId});

  Future<OrderStatusModel> getCheckoutStatus(String orderId);

  Future<void> cancelPayment(String paymentId);

  /// Opens Surfboard's hosted Payment Page in the device's own browser (via
  /// `url_launcher`) — deliberately not an embedded WebView, so the customer
  /// sees a real, trusted browser address bar while entering card details.
  /// Throws if the URL can't be launched; callers treat this as best-effort.
  Future<void> openPaymentUrl(String url);
}
