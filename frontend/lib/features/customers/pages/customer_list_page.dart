import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/animations/fade_slide_in.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../demo_data/providers/demo_data_providers.dart';
import '../controllers/customer_list_controller.dart';
import '../models/customer_query.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_empty_state.dart';
import '../widgets/customer_filter_bar.dart';
import '../widgets/customer_hero_header.dart';
import '../widgets/customer_kpi_showcase_card.dart';
import '../widgets/customer_loading_skeleton.dart';
import '../widgets/customer_recent_searches.dart';
import '../widgets/customer_search_bar.dart';
import '../widgets/customers_illustrated_empty_state.dart';
import 'add_customer_page.dart';
import 'customer_details_page.dart';

/// The Customers tab's root screen — redesigned (Phase UI/UX 7) from a
/// simple CRUD list into a Customer Relationship Management experience,
/// matching the Dashboard/Reports redesign. Search/filter/pagination are
/// entirely unchanged — [CustomerListController] and
/// [CustomerRepository] are consumed exactly as they already exist; only
/// the presentation layer changed. `Total Customers` in the Hero prefers
/// [DemoDataController]'s generated count when present, the same "demo
/// data populates the redesigned UI naturally" fallback Dashboard's own
/// Customers KPI already uses — nowhere else in this page reads demo data,
/// since `DemoCustomer` has no phone/email/status/tags shape to safely
/// stand in for a real [CustomerModel] without fabricating fields.
class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  /// Session-only, in-memory recent-search terms — never persisted (see
  /// `CustomerRecentSearches`'s header comment).
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    final uid = ref.read(authControllerProvider).valueOrNull?.uid;
    if (uid == null) return;
    ref
        .read(customerListControllerProvider(uid).notifier)
        .loadMore()
        .catchError((Object error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Could not load more customers. Pull down to try again.')),
      );
    });
  }

  void _runSearch(String value, String uid) {
    final current =
        ref.read(customerListControllerProvider(uid)).valueOrNull?.query ??
            const CustomerQuery();
    ref.read(customerListControllerProvider(uid).notifier).applyQuery(
        current.copyWith(search: value, clearSearch: value.isEmpty));

    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
  }

  void _onSearchChanged(String value, String uid) {
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 400), () => _runSearch(value, uid));
  }

  void _selectRecentSearch(String term, String uid) {
    _searchController.text = term;
    _searchController.selection = TextSelection.collapsed(offset: term.length);
    _searchDebounce?.cancel();
    _runSearch(term, uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) return const AppFullScreenLoader();

    final provider = customerListControllerProvider(uid);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final statsAsync = ref.watch(customerStatsProvider(uid));
    final demoCustomersCount =
        ref.watch(demoDataControllerProvider(uid)).valueOrNull?.customersCount;

    final stats = statsAsync.valueOrNull;
    final totalCustomers = demoCustomersCount ?? stats?.totalCustomers ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
            children: [
              FadeSlideIn(
                child: CustomerHeroHeader(
                  totalCustomers: totalCustomers,
                  activeCustomers: stats?.activeCustomers ?? 0,
                  newThisMonth: stats?.newThisMonth ?? 0,
                  onSearchTap: () => _searchFocusNode.requestFocus(),
                  onAddCustomer: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddCustomerPage()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (stats != null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Customer Overview'),
                      CustomerKpiHighlightCard(
                        label: 'Total Customers',
                        icon: LucideIcons.users,
                        value: totalCustomers.toDouble(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: CustomerKpiCompactCard(
                                label: 'Returning Customers',
                                icon: LucideIcons.repeat,
                                value: stats.returningCustomers.toDouble(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: CustomerKpiCompactCard(
                                label: 'New This Month',
                                icon: LucideIcons.userPlus,
                                value: stats.newThisMonth.toDouble(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CustomerKpiWideCard(
                        label: 'Average Spend',
                        icon: LucideIcons.dollarSign,
                        value: stats.averageSpend,
                        formatter: (v) => '\$${v.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CustomerKpiMediumCard(
                        label: 'VIP Customers',
                        icon: LucideIcons.star,
                        value: stats.vipCustomers.toDouble(),
                        iconColor: AppColors.warning,
                        iconBackground: AppColors.warningContainer,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          CustomerKpiStatPill(
                            label: 'Lifetime Revenue',
                            icon: LucideIcons.wallet,
                            value: stats.lifetimeRevenue,
                            formatter: (v) => '\$${v.toStringAsFixed(0)}',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          CustomerKpiStatPill(
                            label: 'Inactive Customers',
                            icon: LucideIcons.userX,
                            value: stats.inactiveCustomers.toDouble(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomerSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) => _onSearchChanged(value, uid),
                    ),
                    CustomerRecentSearches(
                      terms: _recentSearches,
                      onSelect: (term) => _selectRecentSearch(term, uid),
                      onClear: () => setState(_recentSearches.clear),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.hasValue)
                      CustomerFilterBar(
                        selected: state.value!.query.filter,
                        onFilterSelected: (filter) => notifier.applyQuery(
                            state.value!.query.copyWith(filter: filter)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              switch (state) {
                AsyncLoading() when !state.hasValue =>
                  const CustomerLoadingSkeleton(),
                AsyncError() when !state.hasValue => ErrorState(
                    message:
                        'Could not load your customers. Please check your connection and try again.',
                    onRetry: notifier.refresh,
                  ),
                _ => FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _CustomerListBody(
                        data: state.value!, notifier: notifier),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerListBody extends StatelessWidget {
  const _CustomerListBody({required this.data, required this.notifier});

  final CustomerListState data;
  final CustomerListController notifier;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return data.query.hasActiveFilters
          ? const CustomerEmptyState(
              title: 'No Results',
              message: 'No customers match your search or filters.',
            )
          : const CustomersIllustratedEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final customer in data.items) ...[
          CustomerCard(
            customer: customer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => CustomerDetailsPage(customerId: customer.id)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (data.hasMore || data.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: AppLoadingIndicator()),
          ),
      ],
    );
  }
}
