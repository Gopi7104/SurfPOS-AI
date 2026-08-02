import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/billing/models/customer_details.dart';

void main() {
  group('CustomerDetails', () {
    test('isEmpty is true when both fields are null', () {
      expect(const CustomerDetails().isEmpty, isTrue);
    });

    test('isEmpty is true when both fields are blank strings', () {
      expect(const CustomerDetails(name: '  ', phone: '').isEmpty, isTrue);
    });

    test('isEmpty is false when either field has content', () {
      expect(const CustomerDetails(phone: '+46701234567').isEmpty, isFalse);
      expect(const CustomerDetails(name: 'Alex').isEmpty, isFalse);
    });

    test('copyWith replaces only the given field', () {
      const details = CustomerDetails(name: 'Alex', phone: '+46701234567');
      final updated = details.copyWith(name: 'Sam');

      expect(updated.name, 'Sam');
      expect(updated.phone, '+46701234567');
    });
  });
}
