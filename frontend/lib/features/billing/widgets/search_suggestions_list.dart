import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/empty_states/empty_state.dart';
import '../../inventory/models/product_model.dart';

/// Live suggestions shown under the search bar while [BillingState.searchQuery]
/// is non-empty — tapping a row immediately adds it to the cart (see
/// docs/22_DEVELOPMENT_ROADMAP.md, Phase 3: "Selecting a suggestion
/// immediately adds it to the cart").
class SearchSuggestionsList extends StatelessWidget {
  const SearchSuggestionsList({
    required this.results,
    required this.isSearching,
    this.errorMessage,
    required this.onSelect,
    super.key,
  });

  final List<ProductModel> results;
  final bool isSearching;
  final String? errorMessage;
  final ValueChanged<ProductModel> onSelect;

  @override
  Widget build(BuildContext context) {
    if (isSearching && results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!,
            style: AppTypography.bodyMD.copyWith(color: AppColors.error)),
      );
    }
    if (results.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.searchX,
        title: 'No matches',
        message: 'No products match that name, SKU, or barcode.',
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          title:
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            'SKU: ${product.sku}${product.barcode != null ? ' · ${product.barcode}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: AppTypography.bodyMD.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          onTap: () => onSelect(product),
        );
      },
    );
  }
}
