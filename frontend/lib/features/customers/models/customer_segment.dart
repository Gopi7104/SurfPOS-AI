import 'customer_model.dart';
import 'customer_status.dart';

/// Automatic customer groupings (Phase CRM-1) — always *computed* live from
/// a [CustomerModel], never stored, so a segment can never drift out of
/// sync with the data it's based on. A customer can belong to any number of
/// these at once (see each customer's badges on `CustomerDetailsPage`, and
/// the real "Returning"/"Inactive"/"Lifetime Revenue" aggregates on
/// `CustomerListPage`, both computed via [computeCustomerSegments]/this
/// file's constants rather than a second source of truth).
enum CustomerSegment {
  newCustomer,
  returning,
  vip,
  inactive,
  highSpender,
  recentVisitor;

  String get label => switch (this) {
        CustomerSegment.newCustomer => 'New Customer',
        CustomerSegment.returning => 'Returning',
        CustomerSegment.vip => 'VIP',
        CustomerSegment.inactive => 'Inactive',
        CustomerSegment.highSpender => 'High Spender',
        CustomerSegment.recentVisitor => 'Recent Visitor',
      };
}

/// Reuses the same $300 threshold `CustomerInsightsSection` already uses for
/// its per-customer "high spending" insight, so "High Spender" means the
/// same thing everywhere in this app rather than two different numbers.
const kHighSpenderThreshold = 300.0;

/// Mirrors `CustomerInsightsSection`'s existing "recently joined" window.
const kNewCustomerWindow = Duration(days: 30);
const kRecentVisitorWindow = Duration(days: 7);
const kInactivityWindow = Duration(days: 90);

/// Pure, deterministic, and cheap enough to call directly from a build
/// method — no provider/caching needed.
List<CustomerSegment> computeCustomerSegments(CustomerModel customer,
    {DateTime? now}) {
  final today = now ?? DateTime.now();
  final isNew = today.difference(customer.memberSince) <= kNewCustomerWindow;
  final lastPurchase = customer.lastPurchaseAt;
  final segments = <CustomerSegment>[];

  if (isNew) segments.add(CustomerSegment.newCustomer);
  if (customer.totalOrders >= 2) segments.add(CustomerSegment.returning);
  if (customer.isVip) segments.add(CustomerSegment.vip);
  if (customer.lifetimeSpend >= kHighSpenderThreshold) {
    segments.add(CustomerSegment.highSpender);
  }
  if (lastPurchase != null &&
      today.difference(lastPurchase) <= kRecentVisitorWindow) {
    segments.add(CustomerSegment.recentVisitor);
  }

  // Behaviorally inactive: been a customer for a while (not "new") with no
  // purchase ever, or none within the inactivity window — folded together
  // with the merchant-settable `CustomerStatus.inactive` flag, since either
  // one means the same thing to a merchant looking at this list.
  final noRecentActivity = lastPurchase == null
      ? !isNew
      : today.difference(lastPurchase) > kInactivityWindow;
  if (customer.status == CustomerStatus.inactive ||
      (!isNew && noRecentActivity)) {
    segments.add(CustomerSegment.inactive);
  }

  return segments;
}
