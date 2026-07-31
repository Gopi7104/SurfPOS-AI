import '../../../core/exceptions/api_exception.dart';

/// User-facing failure message for any merchant-onboarding operation. Never
/// surfaces raw exception types/stack traces to the UI (see
/// docs/07_CODING_RULES.md § 14), mirroring `AuthFailure`.
class MerchantOnboardingFailure {
  const MerchantOnboardingFailure(this.message);

  final String message;

  /// Backend [ApiException] messages are relayed verbatim by default — the
  /// backend already writes human-readable copy — except
  /// [SurfboardUpstreamException], which is deliberately **not** relayed:
  /// the raw message can be Surfboard's own error text (e.g. "Invalid API
  /// key or secret"), which would leak a backend-credential problem to the
  /// end user as if it were something they did wrong.
  factory MerchantOnboardingFailure.fromException(Object error) {
    if (error is ConflictException) {
      return const MerchantOnboardingFailure(
          'You already have a merchant application in progress.');
    }
    if (error is SurfboardUpstreamException) {
      return const MerchantOnboardingFailure(
        'Unable to submit your application right now — please try again in a few minutes.',
      );
    }
    if (error is ApiException) {
      return MerchantOnboardingFailure(error.message);
    }
    return const MerchantOnboardingFailure(
        'Something went wrong. Please try again.');
  }
}
