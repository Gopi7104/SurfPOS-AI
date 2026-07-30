import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/exceptions/api_exception.dart';
import 'package:surfpos_ai/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:surfpos_ai/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:surfpos_ai/features/authentication/domain/auth_failure.dart';

void main() {
  test('GoogleSignInCancelled maps to a cancellation message', () {
    final failure = AuthFailure.fromException(const GoogleSignInCancelled());
    expect(failure.message, 'Google sign-in was cancelled.');
  });

  test('GoogleAccountNotRegistered maps to the sign-up-first message', () {
    final failure =
        AuthFailure.fromException(const GoogleAccountNotRegistered());
    expect(failure.message, contains("isn't registered yet"));
  });

  test('relays ApiException messages verbatim', () {
    const failure =
        ConflictException('An account with this email already exists');
    expect(
      AuthFailure.fromException(failure).message,
      'An account with this email already exists',
    );
  });

  group('FirebaseAuthException mapping', () {
    final cases = {
      'invalid-email': 'Enter a valid email address.',
      'user-not-found': 'Incorrect email or password.',
      'wrong-password': 'Incorrect email or password.',
      'invalid-credential': 'Incorrect email or password.',
      'email-already-in-use': 'An account with this email already exists.',
      'weak-password': 'Choose a stronger password.',
      'network-request-failed':
          'Could not reach the server. Check your internet connection and try again.',
      'too-many-requests':
          'Too many attempts. Please wait a moment and try again.',
      'some-unmapped-code': 'Something went wrong. Please try again.',
    };

    for (final entry in cases.entries) {
      test('code "${entry.key}"', () {
        final failure = AuthFailure.fromException(
          FirebaseAuthException(code: entry.key, message: 'irrelevant'),
        );
        expect(failure.message, entry.value);
      });
    }
  });

  test('falls back to a generic message for unrecognized exceptions', () {
    final failure = AuthFailure.fromException(Exception('anything else'));
    expect(failure.message, 'Something went wrong. Please try again.');
  });
}
