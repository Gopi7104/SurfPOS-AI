import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/validators/auth_validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty input', () {
      expect(validateEmail(''), 'Email is required');
    });

    test('rejects malformed input', () {
      expect(validateEmail('not-an-email'), 'Enter a valid email address');
    });

    test('accepts a valid email', () {
      expect(validateEmail('owner@surfpos.se'), isNull);
    });
  });

  group('validateLoginPassword', () {
    test('rejects empty input', () {
      expect(validateLoginPassword(''), 'Password is required');
    });

    test('accepts any non-empty input regardless of complexity', () {
      expect(validateLoginPassword('short'), isNull);
    });
  });

  group('validateSignupPassword', () {
    test('rejects empty input', () {
      expect(validateSignupPassword(''), 'Password is required');
    });

    test('rejects too-short passwords', () {
      expect(validateSignupPassword('Ab1!'),
          'Password must be at least 8 characters');
    });

    test('rejects missing uppercase', () {
      expect(
        validateSignupPassword('lowercase1!'),
        'Password must include an uppercase letter',
      );
    });

    test('rejects missing lowercase', () {
      expect(
        validateSignupPassword('UPPERCASE1!'),
        'Password must include a lowercase letter',
      );
    });

    test('rejects missing digit', () {
      expect(validateSignupPassword('NoDigitsHere!'),
          'Password must include a number');
    });

    test('rejects missing special character', () {
      expect(
        validateSignupPassword('NoSpecial1Here'),
        'Password must include a special character',
      );
    });

    test('accepts a fully compliant password', () {
      expect(validateSignupPassword('Str0ng!Pass'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('rejects empty input', () {
      expect(
          validateConfirmPassword('Str0ng!Pass', ''), 'Confirm your password');
    });

    test('rejects a mismatch', () {
      expect(
        validateConfirmPassword('Str0ng!Pass', 'Different1!'),
        'Passwords do not match',
      );
    });

    test('accepts a match', () {
      expect(validateConfirmPassword('Str0ng!Pass', 'Str0ng!Pass'), isNull);
    });
  });

  group('validateFullName', () {
    test('rejects empty/whitespace-only input', () {
      expect(validateFullName('   '), 'Full name is required');
    });

    test('accepts a non-empty name', () {
      expect(validateFullName('Jane Doe'), isNull);
    });
  });
}
