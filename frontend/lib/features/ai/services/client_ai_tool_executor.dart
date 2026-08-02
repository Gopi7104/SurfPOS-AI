import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/providers/billing_providers.dart';
import '../../customers/models/customer_query.dart';
import '../../customers/providers/customer_providers.dart';
import '../../demo_data/providers/demo_data_providers.dart';
import '../../reports/providers/reports_providers.dart';
import '../models/ai_chat_reply.dart';

const _noDemoData = "I don't have real sales data to check yet — generate "
    'demo business data first (tell me to "generate demo data", or use '
    "Dashboard's own \"Generate Demo Business\" button).";

const _cartEmpty = 'Your cart is empty.';

/// Executes a backend-detected `client_tool` request (billing/dashboard/
/// reports/customer — see `ai.service.js`'s header comment on why these
/// can't run on the Node backend) by reading the SAME Riverpod providers the
/// Billing/Dashboard/Reports/Customers pages already use — never a second
/// data source, never a fabricated number. Mirrors the Phase AI-2 backend
/// tools' contract: plain natural-language text, honest about demo-vs-real
/// data, and says so plainly when nothing is available rather than
/// inventing one (see MEMORY.md's "no fabricated data" rule).
class ClientAiToolExecutor {
  const ClientAiToolExecutor(this._ref);

  final Ref _ref;

  Future<String> execute(String uid, ClientToolRequest request) {
    return switch (request.tool) {
      'billing' => _billing(uid, request.function, request.params),
      'dashboard' => _dashboard(uid, request.function),
      'reports' => _reports(uid, request.function),
      'customer' => _customer(uid, request.function, request.params),
      _ => Future.value("I don't know how to look that up yet."),
    };
  }

  // ---------------------------------------------------------------------
  // Billing — real, synchronous, client-side cart state (see
  // `BillingController`/`BillingState`) — never mutated here, read-only.
  // ---------------------------------------------------------------------

  Future<String> _billing(
      String uid, String function, Map<String, dynamic> params) async {
    final cart = _ref.read(billingControllerProvider(uid));
    String money(double v) => '\$${v.toStringAsFixed(2)}';

    switch (function) {
      case 'currentCart':
      case 'currentProducts':
        if (cart.isEmpty) return _cartEmpty;
        final lines = cart.items.map((i) =>
            '- ${i.product.name} x${i.quantity} (${money(i.lineSubtotal)})');
        return 'Current cart (${cart.itemCount} item(s)):\n${lines.join('\n')}';
      case 'cartTotal':
      case 'grandTotal':
        return cart.isEmpty
            ? _cartEmpty
            : 'Cart total: ${money(cart.grandTotal)}';
      case 'itemCount':
        return 'You have ${cart.itemCount} item(s) in the cart.';
      case 'discount':
        return cart.isEmpty
            ? _cartEmpty
            : 'Current discount: ${money(cart.discountTotal)}';
      case 'tax':
        return cart.isEmpty
            ? _cartEmpty
            : 'Current tax: ${money(cart.taxTotal)}';
      case 'searchItem':
        if (cart.isEmpty) return _cartEmpty;
        final query = (params['query'] as String?)?.trim().toLowerCase();
        if (query == null || query.isEmpty) {
          return 'What item should I look for in the cart?';
        }
        final matches = cart.items
            .where((i) => i.product.name.toLowerCase().contains(query));
        if (matches.isEmpty) {
          return 'No item matching "$query" in the current cart.';
        }
        return matches
            .map((i) =>
                '- ${i.product.name} x${i.quantity} (${money(i.lineSubtotal)})')
            .join('\n');
      default:
        return "I don't have a way to check that yet.";
    }
  }

  // ---------------------------------------------------------------------
  // Dashboard — demo-backed KPIs (no real sales ledger exists anywhere in
  // this app — see `ReportsRepositoryImpl`'s header comment); real customer
  // count as an honest stand-in for "customers today" (no daily granularity
  // exists for customers, demo or real).
  // ---------------------------------------------------------------------

  Future<String> _dashboard(String uid, String function) async {
    if (function == 'customersToday') {
      final stats = await _ref.read(customerStatsProvider(uid).future);
      return "I don't track new customers specifically for today — you "
          'have ${stats.totalCustomers} customer(s) total '
          '(${stats.newThisMonth} new this month).';
    }

    final demo = await _ref.read(demoDataControllerProvider(uid).future);
    if (demo == null) return _noDemoData;

    switch (function) {
      case 'revenueToday':
        return "Today's revenue (demo data): \$${demo.todaySales.toStringAsFixed(2)}";
      case 'ordersToday':
        return "Today's orders (demo data): ${demo.todayOrders}";
      case 'averageOrderValue':
        return 'Average order value today (demo data): '
            '\$${demo.todayAverageOrderValue.toStringAsFixed(2)}';
      case 'growth':
        final growth = demo.todaySalesGrowth;
        if (growth == null) {
          return "Not enough data yet to compute today's growth.";
        }
        return growth >= 0
            ? 'Sales are up ${growth.toStringAsFixed(0)}% vs yesterday (demo data).'
            : 'Sales are down ${growth.abs().toStringAsFixed(0)}% vs yesterday (demo data).';
      case 'businessInsights':
        if (demo.insights.isEmpty) {
          return "I don't have enough data yet for an insight.";
        }
        return demo.insights.map((i) => '- ${i.message}').join('\n');
      case 'quickStatistics':
        return 'Today (demo data): \$${demo.todaySales.toStringAsFixed(2)} revenue, '
            '${demo.todayOrders} order(s), '
            '\$${demo.todayAverageOrderValue.toStringAsFixed(2)} average order value.';
      default:
        return "I don't have a way to check that yet.";
    }
  }

  // ---------------------------------------------------------------------
  // Reports — inventory health is real (backed by InventoryRepository);
  // every sales-shaped figure is demo-backed (no sales ledger exists).
  // ---------------------------------------------------------------------

  Future<String> _reports(String uid, String function) async {
    if (function == 'inventoryHealth') {
      final state = await _ref.read(reportsControllerProvider(uid).future);
      final o = state.snapshot.inventoryOverview;
      return 'Inventory health: ${o.productsCount} product(s), '
          '${o.lowStockCount} low stock, ${o.outOfStockCount} out of stock, '
          'across ${o.categoriesCount} categories'
          '${o.isApproximate ? ' (approximate — large catalog)' : ''}.';
    }

    final demo = await _ref.read(demoDataControllerProvider(uid).future);
    if (demo == null) return _noDemoData;

    switch (function) {
      case 'revenue':
      case 'revenueSummary':
        return 'Revenue (demo data) — today: \$${demo.todaySales.toStringAsFixed(2)}, '
            'this week: \$${demo.thisWeekSales.toStringAsFixed(2)}, '
            'this month: \$${demo.thisMonthSales.toStringAsFixed(2)}, '
            'all-time: \$${demo.totalRevenue.toStringAsFixed(2)}.';
      case 'today':
        return "Today's sales (demo data): \$${demo.todaySales.toStringAsFixed(2)}, "
            '${demo.todayOrders} order(s).';
      case 'weekly':
        return 'This week (demo data): \$${demo.thisWeekSales.toStringAsFixed(2)}.';
      case 'monthly':
        return 'This month (demo data): \$${demo.thisMonthSales.toStringAsFixed(2)}.';
      case 'ordersToday':
        return "Today's orders (demo data): ${demo.todayOrders}.";
      case 'averageOrder':
        return 'Average order value (demo data): \$${demo.averageOrderValue.toStringAsFixed(2)}.';
      case 'salesTrend':
        final points = demo.salesTrend.where((p) => p.amount > 0).toList();
        if (points.isEmpty) {
          return 'No sales recorded in the last 14 days (demo data).';
        }
        return 'Sales trend, last 14 days (demo data):\n'
            '${points.map((p) => '- ${p.label}: \$${p.amount.toStringAsFixed(2)}').join('\n')}';
      case 'bestSeller':
        final top =
            demo.bestSellers.where((p) => p.unitsSold > 0).take(5).toList();
        if (top.isEmpty) return 'No sales recorded yet (demo data).';
        return 'Best sellers (demo data):\n'
            '${top.map((p) => '- ${p.name}: ${p.unitsSold} sold').join('\n')}';
      case 'paymentBreakdown':
        final slices =
            demo.paymentBreakdown.where((s) => s.amount > 0).toList();
        if (slices.isEmpty) return 'No payments recorded yet (demo data).';
        return 'Payment breakdown (demo data):\n'
            '${slices.map((s) => '- ${s.method}: \$${s.amount.toStringAsFixed(2)} (${s.percentage.toStringAsFixed(0)}%)').join('\n')}';
      case 'topCategory':
        final byCategory = <String, double>{};
        for (final product in demo.products) {
          byCategory[product.category] =
              (byCategory[product.category] ?? 0) + product.revenue;
        }
        final sorted = byCategory.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (sorted.isEmpty) {
          return 'No category sales recorded yet (demo data).';
        }
        return 'Top categories (demo data):\n'
            '${sorted.take(5).map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}';
      case 'kpiMetrics':
        return 'KPIs (demo data): \$${demo.totalRevenue.toStringAsFixed(2)} total revenue, '
            '${demo.totalOrders} order(s), '
            '\$${demo.averageOrderValue.toStringAsFixed(2)} average order value, '
            '\$${demo.totalProfit.toStringAsFixed(2)} profit.';
      default:
        return "I don't have a way to check that yet.";
    }
  }

  // ---------------------------------------------------------------------
  // Customer — real, device-local data (see `CustomerRepositoryImpl`'s
  // header comment). Phase CRM-1's `recordPurchase` hook means
  // lifetimeSpend/totalOrders/loyaltyPoints are now real per-customer
  // figures, so "top customer" and "customer loyalty" can answer for real.
  // ---------------------------------------------------------------------

  Future<String> _customer(
      String uid, String function, Map<String, dynamic> params) async {
    final repository = _ref.read(customerRepositoryProvider(uid));

    switch (function) {
      case 'count':
        final stats = await _ref.read(customerStatsProvider(uid).future);
        return 'You have ${stats.totalCustomers} customer(s).';
      case 'customerStatistics':
        final stats = await _ref.read(customerStatsProvider(uid).future);
        return 'Customer statistics: ${stats.totalCustomers} total, '
            '${stats.newThisMonth} new this month, '
            '${stats.activeCustomers} active, ${stats.vipCustomers} VIP.';
      case 'vipCustomers':
        final page = await repository.listCustomers(
          const CustomerQuery(filter: CustomerFilter.vip),
          limit: 10,
        );
        if (page.items.isEmpty) return "You don't have any VIP customers yet.";
        return 'VIP customer(s):\n'
            '${page.items.map((c) => '- ${c.firstName} ${c.lastName}').join('\n')}';
      case 'topCustomer':
        final page = await repository.listCustomers(
          const CustomerQuery(filter: CustomerFilter.highestSpending),
          limit: 1,
        );
        if (page.items.isEmpty || page.items.first.lifetimeSpend <= 0) {
          return "I don't have any purchase history to determine a top "
              'customer yet.';
        }
        final top = page.items.first;
        return 'Your top customer is ${top.firstName} ${top.lastName} — '
            '\$${top.lifetimeSpend.toStringAsFixed(2)} lifetime spend.';
      case 'recentCustomer':
        final page = await repository.listCustomers(
          const CustomerQuery(filter: CustomerFilter.recentlyAdded),
          limit: 5,
        );
        if (page.items.isEmpty) return "You don't have any customers yet.";
        return 'Most recently added customer(s):\n'
            '${page.items.map((c) => '- ${c.firstName} ${c.lastName}').join('\n')}';
      case 'loyalty':
        final query = (params['query'] as String?)?.trim();
        if (query == null || query.isEmpty) {
          final page = await repository.listCustomers(
            const CustomerQuery(filter: CustomerFilter.highestSpending),
            limit: 5,
          );
          if (page.items.isEmpty) return "You don't have any customers yet.";
          return 'Loyalty points:\n'
              '${page.items.map((c) => '- ${c.firstName} ${c.lastName}: ${c.loyaltyPoints} points (${c.membershipTier.label})').join('\n')}';
        }
        final page = await repository.listCustomers(
          CustomerQuery(search: query),
          limit: 1,
        );
        if (page.items.isEmpty) return 'No customer found matching "$query".';
        final customer = page.items.first;
        return '${customer.firstName} ${customer.lastName} has '
            '${customer.loyaltyPoints} loyalty points '
            '(${customer.membershipTier.label} tier).';
      case 'search':
        final query = (params['query'] as String?)?.trim();
        if (query == null || query.isEmpty) {
          return 'Which customer should I search for?';
        }
        final page = await repository.listCustomers(
          CustomerQuery(search: query),
          limit: 5,
        );
        if (page.items.isEmpty) return 'No customer found matching "$query".';
        return page.items
            .map((c) => '- ${c.firstName} ${c.lastName}')
            .join('\n');
      default:
        return "I don't have a way to check that yet.";
    }
  }
}
