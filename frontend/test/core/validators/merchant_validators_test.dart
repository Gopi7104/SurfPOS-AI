import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/core/validators/merchant_validators.dart';

void main() {
  group('validateCorporateId', () {
    test('requires a non-empty value', () {
      expect(validateCorporateId(''), isNotNull);
      expect(validateCorporateId('   '), isNotNull);
      expect(validateCorporateId('1234567812'), isNull);
    });
  });

  group('validateCountryCode', () {
    test('requires exactly 2 letters', () {
      expect(validateCountryCode(''), isNotNull);
      expect(validateCountryCode('S'), isNotNull);
      expect(validateCountryCode('SWE'), isNotNull);
      expect(validateCountryCode('SE'), isNull);
      expect(validateCountryCode('se'), isNull);
    });
  });

  group('validateMccCode', () {
    test('is optional — empty is valid', () {
      expect(validateMccCode(''), isNull);
    });

    test('must be exactly 4 digits when provided', () {
      expect(validateMccCode('594'), isNotNull);
      expect(validateMccCode('59411'), isNotNull);
      expect(validateMccCode('abcd'), isNotNull);
      expect(validateMccCode('5941'), isNull);
    });
  });

  group('validateEmail', () {
    test('requires a valid email format', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('not-an-email'), isNotNull);
      expect(validateEmail('owner@example.com'), isNull);
    });
  });

  group('validatePhoneCode', () {
    test('requires digits only, no +', () {
      expect(validatePhoneCode(''), isNotNull);
      expect(validatePhoneCode('+46'), isNotNull);
      expect(validatePhoneCode('46'), isNull);
    });
  });

  group('validatePhoneNumber', () {
    test('requires 5-15 digits', () {
      expect(validatePhoneNumber(''), isNotNull);
      expect(validatePhoneNumber('1234'), isNotNull);
      expect(validatePhoneNumber('1234567890123456'), isNotNull);
      expect(validatePhoneNumber('701234567'), isNull);
    });
  });

  group('address field validators', () {
    test('addressLine1/city/postalCode/storeName are all required', () {
      expect(validateAddressLine1(''), isNotNull);
      expect(validateAddressLine1('Main St 1'), isNull);
      expect(validateCity(''), isNotNull);
      expect(validateCity('Stockholm'), isNull);
      expect(validatePostalCode(''), isNotNull);
      expect(validatePostalCode('123 45'), isNull);
      expect(validateStoreName(''), isNotNull);
      expect(validateStoreName('Main Street Store'), isNull);
    });
  });
}
