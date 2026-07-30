import 'package:dio/dio.dart';

import '../exceptions/api_exception.dart';
import 'api_config.dart';

/// The single HTTP client every backend call goes through (see
/// docs/07_CODING_RULES.md § 13 / § 3 — "a single `ApiClient` (dio) wrapper
/// is the only network layer"). Unwraps the backend's standard envelope
/// (`{success, data}` / `{success:false, error:{code,message,details}}` —
/// see docs/04_API_DOCUMENTATION.md § 1) into either a plain `Map` or a
/// typed [ApiException] — callers never touch a raw [Response].
///
/// The `Authorization: Bearer <token>` header is attached per-request via
/// [authTokenProvider], not read from storage here — the token itself is
/// never persisted by this app (see [ApiClient] callers in
/// `features/authentication/data/datasources/auth_api_service.dart`); it's
/// sourced fresh from Firebase's own session on every authenticated call.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl, this.authTokenProvider})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? ApiConfig.baseUrl));

  final Dio _dio;

  /// Returns a fresh bearer token for the current session, or `null` if
  /// there isn't one. Only consulted when a call passes `requiresAuth: true`.
  final Future<String?> Function()? authTokenProvider;

  Future<Map<String, dynamic>> get(String path, {bool requiresAuth = false}) {
    return _send(
        () async => _dio.get(path, options: await _optionsFor(requiresAuth)));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) {
    return _send(
      () async =>
          _dio.post(path, data: body, options: await _optionsFor(requiresAuth)),
    );
  }

  Future<Options> _optionsFor(bool requiresAuth) async {
    if (!requiresAuth) return Options();
    final token = await authTokenProvider?.call();
    return Options(
        headers: token == null ? null : {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> _send(
      Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return _unwrapSuccess(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Map<String, dynamic> _unwrapSuccess(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      final data = body['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    }
    throw const UnknownApiException('Unexpected response from server.');
  }

  ApiException _mapDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      // No response reached us at all: timeout, DNS failure, connection
      // refused (backend not running/unreachable), or no device connectivity.
      return const NetworkException(
        'Could not reach the server. Check your internet connection and try again.',
      );
    }

    final body = response.data;
    if (body is! Map<String, dynamic> ||
        body['error'] is! Map<String, dynamic>) {
      return UnknownApiException(
        'Unexpected error response from server (HTTP ${response.statusCode}).',
      );
    }

    final errorBody = body['error'] as Map<String, dynamic>;
    final code = errorBody['code'] as String? ?? 'INTERNAL_ERROR';
    final message = errorBody['message'] as String? ?? 'Something went wrong.';
    final details = (errorBody['details'] as List<dynamic>? ?? [])
        .map((d) => ApiErrorDetail.fromJson(d as Map<String, dynamic>))
        .toList();

    return switch (code) {
      'VALIDATION_ERROR' => ValidationException(message, details: details),
      'UNAUTHENTICATED' => UnauthenticatedException(message),
      'FORBIDDEN' => ForbiddenException(message),
      'NOT_FOUND' => NotFoundApiException(message),
      'CONFLICT' => ConflictException(message),
      'RATE_LIMITED' => RateLimitedException(message),
      'INTERNAL_ERROR' => InternalServerException(message),
      _ => UnknownApiException(message),
    };
  }
}
