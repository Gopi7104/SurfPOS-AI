import '../models/checkout_item.dart';
import '../models/checkout_result_model.dart';
import '../models/order_status_model.dart';
import '../models/test_payment_result.dart';
import 'payment_repository.dart';

/// Development-only stand-in for [PaymentRepository] — implements the same
/// seam [PaymentController]/[TestPaymentController] talk to, but never makes
/// a network call, never talks to Surfboard, and never opens a browser. See
/// docs/22_DEVELOPMENT_ROADMAP.md Phase 4.5 — this exists purely so QA/dev
/// builds can exercise Checkout → Receipt → Print/Share without a live
/// Surfboard sandbox order.
///
/// [TestPaymentController] only ever calls [createCheckout] — the other
/// methods exist solely to satisfy the interface; a test payment always
/// completes on its own and is never polled, retried, or cancelled through
/// Surfboard.
class TestPaymentRepository implements PaymentRepository {
  @override
  Future<CheckoutResultModel> createCheckout(
      {String? storeId, required List<CheckoutItem> items}) async {
    final result = TestPaymentResult.generate();
    return CheckoutResultModel(
      orderId: result.reference,
      storeId: storeId,
      paymentId: result.paymentId,
    );
  }

  @override
  Future<CheckoutResultModel> retryPayment(
      {required String orderId, required String storeId}) {
    throw UnsupportedError(
        'Test payments cannot be retried — start a new Test Payment instead.');
  }

  @override
  Future<OrderStatusModel> getCheckoutStatus(String orderId) async {
    return const OrderStatusModel(
      orderStatus: 'PAYMENT_COMPLETED',
      paymentStatus: 'PAYMENT_COMPLETED',
      paymentMethod: TestPaymentResult.method,
    );
  }

  @override
  Future<void> cancelPayment(String paymentId) async {}

  @override
  Future<void> openPaymentUrl(String url) async {}
}
