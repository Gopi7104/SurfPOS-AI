/// Typed exception hierarchy mirroring the backend's error codes exactly
/// (see docs/04_API_DOCUMENTATION.md § 1 and `backend/src/constants/errorCodes.js`).
///
/// Backend error `message` strings are relayed verbatim in [message] — the
/// backend already writes human-readable copy ("An account with this email
/// already exists"), so there's no reason to re-author it client-side.
/// [NetworkException] and [UnknownApiException] are the two cases with no
/// backend message to relay, since nothing was reached to produce one.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.details = const []});

  final String message;
  final List<ApiErrorDetail> details;

  @override
  String toString() => message;
}

class ApiErrorDetail {
  const ApiErrorDetail({required this.path, required this.message});

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) => ApiErrorDetail(
        path: json['path'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  final String path;
  final String message;
}

/// 400 VALIDATION_ERROR
class ValidationException extends ApiException {
  const ValidationException(super.message, {super.details});
}

/// 401 UNAUTHENTICATED
class UnauthenticatedException extends ApiException {
  const UnauthenticatedException(super.message);
}

/// 403 FORBIDDEN
class ForbiddenException extends ApiException {
  const ForbiddenException(super.message);
}

/// 404 NOT_FOUND
class NotFoundApiException extends ApiException {
  const NotFoundApiException(super.message);
}

/// 409 CONFLICT
class ConflictException extends ApiException {
  const ConflictException(super.message);
}

/// 429 RATE_LIMITED
class RateLimitedException extends ApiException {
  const RateLimitedException(super.message);
}

/// 500 INTERNAL_ERROR — includes the backend-not-configured case surfaced
/// while no real Firebase project exists yet (see .claude/decision.md).
class InternalServerException extends ApiException {
  const InternalServerException(super.message);
}

/// No HTTP response at all — timeout, DNS failure, connection refused
/// (backend unreachable/not running), or no device connectivity.
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// An error code the client doesn't recognize, or a response that doesn't
/// match the standard envelope at all. Kept distinct from [NetworkException]
/// so future new backend error codes fail safe instead of crashing.
class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);
}
