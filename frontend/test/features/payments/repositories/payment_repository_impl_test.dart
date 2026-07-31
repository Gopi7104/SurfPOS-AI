import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:surfpos_ai/core/network/api_client.dart';
import 'package:surfpos_ai/features/payments/models/checkout_item.dart';
import 'package:surfpos_ai/features/payments/repositories/payment_repository_impl.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _response(Map<String, dynamic> body) {
  return Response(
      data: body,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/whatever'));
}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  late MockDio dio;
  late ApiClient apiClient;
  late PaymentRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    apiClient = ApiClient(dio: dio, baseUrl: 'http://localhost:4000');
    repository = PaymentRepositoryImpl(apiClient: apiClient);
  });

  test(
      'createCheckout posts productId/quantity line items and parses the checkout result',
      () async {
    when(() => dio.post('/payments/checkout',
        data: any(named: 'data'), options: any(named: 'options'))).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {
          'checkout': {
            'orderId': 'order-1',
            'storeId': 'store-1',
            'subtotal': 100,
            'discountTotal': 0,
            'taxTotal': 25,
            'amount': 125,
            'paymentId': 'pay-1',
            'paymentUrl': 'https://pay.example/order-1',
          },
        },
      }),
    );

    final result = await repository.createCheckout(
      storeId: 'store-1',
      items: const [CheckoutItem(productId: 'p1', quantity: 2)],
    );

    final captured = verify(
      () => dio.post('/payments/checkout',
          data: captureAny(named: 'data'), options: any(named: 'options')),
    ).captured.single as Map<String, dynamic>;
    expect(captured['storeId'], 'store-1');
    expect(captured['items'], [
      {'productId': 'p1', 'quantity': 2},
    ]);

    expect(result.orderId, 'order-1');
    expect(result.paymentId, 'pay-1');
    expect(result.paymentUrl, 'https://pay.example/order-1');
    expect(result.amount, 125);
  });

  test('retryPayment posts to the retry endpoint with the given storeId',
      () async {
    when(() => dio.post(
          '/payments/checkout/order-1/retry',
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {
          'checkout': {
            'orderId': 'order-1',
            'paymentId': 'pay-2',
            'paymentUrl': 'https://pay.example/retry'
          }
        },
      }),
    );

    final result =
        await repository.retryPayment(orderId: 'order-1', storeId: 'store-1');

    verify(() => dio.post(
          '/payments/checkout/order-1/retry',
          data: {'storeId': 'store-1'},
          options: any(named: 'options'),
        )).called(1);
    expect(result.paymentId, 'pay-2');
    expect(result.paymentUrl, 'https://pay.example/retry');
  });

  test('getCheckoutStatus GETs the order status endpoint and parses the status',
      () async {
    when(() => dio.get('/payments/checkout/order-1/status',
        options: any(named: 'options'))).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {
          'status': {
            'orderStatus': 'PAYMENT_COMPLETED',
            'paymentStatus': 'PAYMENT_COMPLETED',
            'paymentId': 'pay-1',
            'paymentMethod': 'CARD',
            'amount': 125,
            'transactionId': 'txn-1',
          },
        },
      }),
    );

    final status = await repository.getCheckoutStatus('order-1');

    expect(status.orderStatus, 'PAYMENT_COMPLETED');
    expect(status.paymentStatus, 'PAYMENT_COMPLETED');
    expect(status.transactionId, 'txn-1');
  });

  test('cancelPayment DELETEs the payment endpoint', () async {
    when(() => dio.delete('/payments/pay-1', options: any(named: 'options')))
        .thenAnswer((_) async => _response({'success': true, 'data': {}}));

    await repository.cancelPayment('pay-1');

    verify(() => dio.delete('/payments/pay-1', options: any(named: 'options')))
        .called(1);
  });
}
