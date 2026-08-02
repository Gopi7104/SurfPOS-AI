import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/customers/models/customer_model.dart';
import 'package:surfpos_ai/features/customers/models/customer_segment.dart';
import 'package:surfpos_ai/features/customers/models/customer_status.dart';

CustomerModel _customer({
  DateTime? memberSince,
  int totalOrders = 0,
  double lifetimeSpend = 0,
  DateTime? lastPurchaseAt,
  List<String> tags = const [],
  CustomerStatus status = CustomerStatus.active,
}) {
  return CustomerModel(
    id: 'CUST-1',
    firstName: 'Alex',
    lastName: 'Rivera',
    phone: '555-0100',
    memberSince: memberSince ?? DateTime(2020),
    totalOrders: totalOrders,
    lifetimeSpend: lifetimeSpend,
    lastPurchaseAt: lastPurchaseAt,
    tags: tags,
    status: status,
  );
}

void main() {
  final now = DateTime(2026, 6, 15);

  group('computeCustomerSegments', () {
    test('a brand-new customer with no orders is New Customer only', () {
      final customer =
          _customer(memberSince: now.subtract(const Duration(days: 5)));

      expect(computeCustomerSegments(customer, now: now),
          [CustomerSegment.newCustomer]);
    });

    test('2+ orders marks Returning', () {
      final customer = _customer(
        memberSince: now.subtract(const Duration(days: 200)),
        totalOrders: 2,
        lastPurchaseAt: now.subtract(const Duration(days: 1)),
      );

      final segments = computeCustomerSegments(customer, now: now);

      expect(segments, contains(CustomerSegment.returning));
    });

    test('VIP tag marks Vip', () {
      final customer = _customer(
        memberSince: now.subtract(const Duration(days: 200)),
        tags: const ['VIP'],
        lastPurchaseAt: now.subtract(const Duration(days: 1)),
      );

      expect(computeCustomerSegments(customer, now: now),
          contains(CustomerSegment.vip));
    });

    test('lifetime spend at or above the threshold marks High Spender', () {
      final customer = _customer(
        memberSince: now.subtract(const Duration(days: 200)),
        lifetimeSpend: kHighSpenderThreshold,
        lastPurchaseAt: now.subtract(const Duration(days: 1)),
      );

      expect(computeCustomerSegments(customer, now: now),
          contains(CustomerSegment.highSpender));
    });

    test('a purchase within the last 7 days marks Recent Visitor', () {
      final customer = _customer(
        memberSince: now.subtract(const Duration(days: 200)),
        lastPurchaseAt: now.subtract(const Duration(days: 2)),
      );

      expect(computeCustomerSegments(customer, now: now),
          contains(CustomerSegment.recentVisitor));
    });

    test('no purchase ever and not new is Inactive', () {
      final customer =
          _customer(memberSince: now.subtract(const Duration(days: 200)));

      expect(computeCustomerSegments(customer, now: now),
          contains(CustomerSegment.inactive));
    });

    test('last purchase beyond the inactivity window is Inactive', () {
      final customer = _customer(
        memberSince: now.subtract(const Duration(days: 400)),
        lastPurchaseAt: now.subtract(const Duration(days: 100)),
        totalOrders: 5,
      );

      expect(computeCustomerSegments(customer, now: now),
          contains(CustomerSegment.inactive));
    });

    test(
        'the merchant-set inactive status always marks Inactive, regardless of activity',
        () {
      final customer = _customer(
        memberSince: now.subtract(const Duration(days: 200)),
        lastPurchaseAt: now.subtract(const Duration(days: 1)),
        totalOrders: 5,
        status: CustomerStatus.inactive,
      );

      expect(computeCustomerSegments(customer, now: now),
          contains(CustomerSegment.inactive));
    });

    test('a recently active, established customer is neither New nor Inactive',
        () {
      final customer = _customer(
        memberSince: now.subtract(const Duration(days: 200)),
        lastPurchaseAt: now.subtract(const Duration(days: 30)),
        totalOrders: 3,
      );

      final segments = computeCustomerSegments(customer, now: now);

      expect(segments, isNot(contains(CustomerSegment.newCustomer)));
      expect(segments, isNot(contains(CustomerSegment.inactive)));
    });
  });
}
