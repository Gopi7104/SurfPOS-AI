import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/themes/app_spacing.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_fab.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../controllers/customer_list_controller.dart';
import '../models/customer_query.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_empty_state.dart';
import '../widgets/customer_filter_bar.dart';
import '../widgets/customer_loading_skeleton.dart';
import '../widgets/customer_search_bar.dart';
import '../widgets/customer_stats_card.dart';
import 'add_customer_page.dart';
import 'customer_details_page.dart';

/// Search + filter + paginated customer list — the Customer Management
/// module's home screen (Phase 6). Search/filter both live in one
/// [CustomerQuery] the controller re-fetches from on every change;
/// infinite scroll appends pages, pull-to-refresh reloads page one —
/// same shape as `ProductListPage`.
class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
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

  void _onSearchChanged(String value, String uid) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final current =
          ref.read(customerListControllerProvider(uid)).valueOrNull?.query ??
              const CustomerQuery();
      ref.read(customerListControllerProvider(uid).notifier).applyQuery(
          current.copyWith(search: value, clearSearch: value.isEmpty));
    });
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

    return Scaffold(
      appBar: const AppTopBar(title: 'Customers'),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AppFab(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add Customer',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddCustomerPage()),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (statsAsync.hasValue) ...[
                CustomerStatsCard(stats: statsAsync.value!),
                const SizedBox(height: AppSpacing.md),
              ],
              CustomerSearchBar(
                controller: _searchController,
                onChanged: (value) => _onSearchChanged(value, uid),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.hasValue)
                CustomerFilterBar(
                  selected: state.value!.query.filter,
                  onFilterSelected: (filter) => notifier
                      .applyQuery(state.value!.query.copyWith(filter: filter)),
                ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: switch (state) {
                  AsyncLoading() when !state.hasValue =>
                    const CustomerLoadingSkeleton(),
                  AsyncError() when !state.hasValue => ErrorState(
                      message:
                          'Could not load your customers. Please check your connection and try again.',
                      onRetry: notifier.refresh,
                    ),
                  _ => _CustomerListBody(
                      data: state.value!,
                      notifier: notifier,
                      scrollController: _scrollController,
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerListBody extends StatelessWidget {
  const _CustomerListBody(
      {required this.data,
      required this.notifier,
      required this.scrollController});

  final CustomerListState data;
  final CustomerListController notifier;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: data.query.hasActiveFilters
                  ? const CustomerEmptyState(
                      title: 'No Results',
                      message: 'No customers match your search or filters.',
                    )
                  : CustomerEmptyState(
                      title: 'No Customers',
                      message: 'Add your first customer to get started.',
                      actionLabel: 'Add Customer',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AddCustomerPage()),
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 120),
        itemCount:
            data.items.length + (data.hasMore || data.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= data.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: AppLoadingIndicator()),
            );
          }
          final customer = data.items[index];
          return CustomerCard(
            customer: customer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => CustomerDetailsPage(customerId: customer.id)),
            ),
          );
        },
      ),
    );
  }
}
