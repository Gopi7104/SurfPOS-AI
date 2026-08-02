import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/skeleton_list.dart';
import '../../authentication/providers/auth_providers.dart';
import '../providers/inventory_providers.dart';
import 'inventory_home_page.dart';

/// Every distinct category currently in use across the catalog — tapping
/// one opens Inventory Home pre-filtered to it.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final categoriesAsync = ref.watch(inventoryCategoriesProvider(uid));

    return Scaffold(
      appBar: AppTopBar(
          title: 'Categories', onBack: () => Navigator.of(context).pop()),
      body: switch (categoriesAsync) {
        AsyncLoading() when !categoriesAsync.hasValue => const SkeletonList(),
        AsyncError() when !categoriesAsync.hasValue => ErrorState(
            message: 'Could not load categories.',
            onRetry: () => ref.invalidate(inventoryCategoriesProvider(uid)),
          ),
        _ when (categoriesAsync.value ?? const []).isEmpty => const EmptyState(
            icon: LucideIcons.tag,
            title: 'No Categories Yet',
            message:
                'Categories will show up here once your products have one set.',
          ),
        _ => _CategoriesList(categories: categoriesAsync.value!),
      },
    );
  }
}

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: const Icon(LucideIcons.tag, color: AppColors.primary),
          title: Text(category),
          trailing: const Icon(LucideIcons.chevronRight, size: 18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => InventoryHomePage(initialCategory: category)),
          ),
        );
      },
    );
  }
}
