import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:surfpos_ai/core/network/api_client.dart';
import 'package:surfpos_ai/features/dashboard/repositories/dashboard_repository_impl.dart';
import 'package:surfpos_ai/features/merchant/data/datasources/merchant_onboarding_api_service.dart';
import 'package:surfpos_ai/features/merchant/data/models/merchant_application.dart';

class MockDio extends Mock implements Dio {}

class MockMerchantOnboardingApiService extends Mock
    implements MerchantOnboardingApiService {}

Response<dynamic> _response(Map<String, dynamic> body) {
  return Response(
      data: body,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/whatever'));
}

MerchantApplication _application({String? merchantId, String? storeId}) {
  final now = DateTime.utc(2026, 1, 1);
  return MerchantApplication(
    applicationId: 'app-1',
    merchantId: merchantId,
    storeId: storeId,
    applicationStatus: merchantId == null
        ? ApplicationStatus.applicationInitiated
        : ApplicationStatus.merchantCreated,
    applicationUrl: 'https://surfkyb.com/app-1',
    shortLinkUrl: null,
    submittedAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  late MockDio dio;
  late ApiClient apiClient;
  late MockMerchantOnboardingApiService merchantApplicationApi;
  late DashboardRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    apiClient = ApiClient(dio: dio, baseUrl: 'http://localhost:4000');
    merchantApplicationApi = MockMerchantOnboardingApiService();
    repository = DashboardRepositoryImpl(
        apiClient: apiClient, merchantApplicationApi: merchantApplicationApi);
  });

  test('returns hasMerchant:false when the caller has no application yet',
      () async {
    when(() => merchantApplicationApi.list()).thenAnswer((_) async => []);

    final result = await repository.loadDashboard();

    expect(result.hasMerchant, isFalse);
    verifyNever(() => dio.get(any(), options: any(named: 'options')));
  });

  test(
      'does not fetch a merchant/store profile while merchantId/storeId are not assigned yet',
      () async {
    when(() => merchantApplicationApi.list())
        .thenAnswer((_) async => [_application()]);

    final result = await repository.loadDashboard();

    expect(result.hasMerchant, isTrue);
    expect(result.merchant, isNull);
    expect(result.store, isNull);
    verifyNever(() => dio.get(any(), options: any(named: 'options')));
  });

  test(
      'fetches and composes the live Merchant and Store profile once ids are assigned',
      () async {
    when(() => merchantApplicationApi.list()).thenAnswer(
        (_) async => [_application(merchantId: 'm-1', storeId: 's-1')]);
    when(() => dio.get('/merchant', options: any(named: 'options'))).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {
          'merchant': {
            'id': 'm-1',
            'name': 'Blue Wave Surf Shop',
            'companyId': '5560360793'
          },
        },
      }),
    );
    when(() => dio.get('/stores/s-1', options: any(named: 'options')))
        .thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {
          'store': {
            'id': 's-1',
            'merchantId': 'm-1',
            'name': 'Main Street Store',
            'status': 'ACTIVE'
          },
        },
      }),
    );

    final result = await repository.loadDashboard();

    expect(result.hasMerchant, isTrue);
    expect(result.merchant?.name, 'Blue Wave Surf Shop');
    expect(result.store?.name, 'Main Street Store');
    expect(result.store?.status, 'ACTIVE');
  });
}
