import 'package:surfpos_ai/features/payments/models/checkout_item.dart';
import 'package:surfpos_ai/features/payments/models/checkout_result_model.dart';
import 'package:surfpos_ai/features/payments/models/order_status_model.dart';
import 'package:surfpos_ai/features/payments/repositories/payment_repository.dart';

/// Configurable [PaymentRepository] test double — mirrors every other fake
/// repository in this app: every method defaults to a no-op/empty behavior,
/// overridable per test via the constructor, never touching the real network.
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({
    Future<CheckoutResultModel> Function(
            {String? storeId, required List<CheckoutItem> items})?
        createCheckout,
    Future<CheckoutResultModel> Function(
            {required String orderId, required String storeId})?
        retryPayment,
    Future<OrderStatusModel> Function(String orderId)? getCheckoutStatus,
    Future<void> Function(String paymentId)? cancelPayment,
    Future<void> Function(String url)? openPaymentUrl,
  })  : _createCheckout = createCheckout ??
            (({storeId, required items}) async =>
                const CheckoutResultModel(orderId: 'order-1')),
        _retryPayment = retryPayment ??
            (({required orderId, required storeId}) async =>
                CheckoutResultModel(orderId: orderId)),
        _getCheckoutStatus =
            getCheckoutStatus ?? ((orderId) async => const OrderStatusModel()),
        _cancelPayment = cancelPayment ?? ((paymentId) async {}),
        _openPaymentUrl = openPaymentUrl ?? ((url) async {});

  final Future<CheckoutResultModel> Function(
      {String? storeId, required List<CheckoutItem> items}) _createCheckout;
  final Future<CheckoutResultModel> Function(
      {required String orderId, required String storeId}) _retryPayment;
  final Future<OrderStatusModel> Function(String orderId) _getCheckoutStatus;
  final Future<void> Function(String paymentId) _cancelPayment;
  final Future<void> Function(String url) _openPaymentUrl;

  @override
  Future<CheckoutResultModel> createCheckout(
          {String? storeId, required List<CheckoutItem> items}) =>
      _createCheckout(storeId: storeId, items: items);

  @override
  Future<CheckoutResultModel> retryPayment(
          {required String orderId, required String storeId}) =>
      _retryPayment(orderId: orderId, storeId: storeId);

  @override
  Future<OrderStatusModel> getCheckoutStatus(String orderId) =>
      _getCheckoutStatus(orderId);

  @override
  Future<void> cancelPayment(String paymentId) => _cancelPayment(paymentId);

  @override
  Future<void> openPaymentUrl(String url) => _openPaymentUrl(url);
}
