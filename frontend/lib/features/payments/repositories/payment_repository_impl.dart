import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../models/checkout_item.dart';
import '../models/checkout_result_model.dart';
import '../models/order_status_model.dart';
import 'payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<CheckoutResultModel> createCheckout(
      {String? storeId, required List<CheckoutItem> items}) async {
    final data = await _apiClient.post(
      '/payments/checkout',
      requiresAuth: true,
      body: {
        if (storeId != null) 'storeId': storeId,
        'items': items.map((item) => item.toJson()).toList(),
      },
    );
    return CheckoutResultModel.fromJson(
        data['checkout'] as Map<String, dynamic>);
  }

  @override
  Future<CheckoutResultModel> retryPayment(
      {required String orderId, required String storeId}) async {
    final data = await _apiClient.post(
      '/payments/checkout/$orderId/retry',
      requiresAuth: true,
      body: {'storeId': storeId},
    );
    return CheckoutResultModel.fromJson(
        data['checkout'] as Map<String, dynamic>);
  }

  @override
  Future<OrderStatusModel> getCheckoutStatus(String orderId) async {
    final data = await _apiClient.get('/payments/checkout/$orderId/status',
        requiresAuth: true);
    return OrderStatusModel.fromJson(data['status'] as Map<String, dynamic>);
  }

  @override
  Future<void> cancelPayment(String paymentId) async {
    await _apiClient.delete('/payments/$paymentId', requiresAuth: true);
  }

  @override
  Future<void> openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not open the payment page.');
    }
  }
}
