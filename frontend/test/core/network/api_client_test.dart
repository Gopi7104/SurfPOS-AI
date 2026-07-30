import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:surfpos_ai/core/exceptions/api_exception.dart';
import 'package:surfpos_ai/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _response(Map<String, dynamic> body, {int statusCode = 200}) {
  return Response(
    data: body,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: '/whatever'),
  );
}

DioException _dioError({Response<dynamic>? response}) {
  return DioException(
    requestOptions: RequestOptions(path: '/whatever'),
    response: response,
    type: response == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  late MockDio dio;
  late ApiClient client;

  setUp(() {
    dio = MockDio();
    client = ApiClient(dio: dio, baseUrl: 'http://localhost:4000');
  });

  test('get() unwraps a successful envelope into its data map', () async {
    when(() => dio.get(any(), options: any(named: 'options'))).thenAnswer(
      (_) async => _response({
        'success': true,
        'data': {'user': 'jane'},
      }),
    );

    final result = await client.get('/auth/me');

    expect(result, {'user': 'jane'});
  });

  test('post() attaches an Authorization header when requiresAuth is true',
      () async {
    when(
      () => dio.post(any(),
          data: any(named: 'data'), options: any(named: 'options')),
    ).thenAnswer(
        (_) async => _response({'success': true, 'data': <String, dynamic>{}}));

    final authedClient = ApiClient(
      dio: dio,
      baseUrl: 'http://localhost:4000',
      authTokenProvider: () async => 'a-fresh-id-token',
    );

    await authedClient.post('/auth/logout', requiresAuth: true);

    final captured = verify(
      () => dio.post(any(),
          data: any(named: 'data'), options: captureAny(named: 'options')),
    ).captured.single as Options;

    expect(captured.headers?['Authorization'], 'Bearer a-fresh-id-token');
  });

  test('maps a response-less DioException to NetworkException', () async {
    when(() => dio.get(any(), options: any(named: 'options')))
        .thenThrow(_dioError());

    expect(() => client.get('/auth/me'), throwsA(isA<NetworkException>()));
  });

  test('maps each backend error code to its matching ApiException subtype',
      () async {
    final cases = {
      'VALIDATION_ERROR': isA<ValidationException>(),
      'UNAUTHENTICATED': isA<UnauthenticatedException>(),
      'FORBIDDEN': isA<ForbiddenException>(),
      'NOT_FOUND': isA<NotFoundApiException>(),
      'CONFLICT': isA<ConflictException>(),
      'RATE_LIMITED': isA<RateLimitedException>(),
      'INTERNAL_ERROR': isA<InternalServerException>(),
      'SOMETHING_NEW': isA<UnknownApiException>(),
    };

    for (final entry in cases.entries) {
      when(() => dio.get(any(), options: any(named: 'options'))).thenThrow(
        _dioError(
          response: _response({
            'success': false,
            'error': {'code': entry.key, 'message': 'Boom'},
          }, statusCode: 400),
        ),
      );

      await expectLater(client.get('/x'), throwsA(entry.value));
    }
  });

  test('ValidationException carries field-level details', () async {
    when(() => dio.get(any(), options: any(named: 'options'))).thenThrow(
      _dioError(
        response: _response({
          'success': false,
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Invalid request',
            'details': [
              {'path': 'email', 'message': 'Invalid email'},
            ],
          },
        }, statusCode: 400),
      ),
    );

    try {
      await client.get('/x');
      fail('expected a ValidationException');
    } on ValidationException catch (error) {
      expect(error.details, hasLength(1));
      expect(error.details.single.path, 'email');
      expect(error.details.single.message, 'Invalid email');
    }
  });
}
