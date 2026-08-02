import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/section_card.dart';

/// Favourite Products (Phase CRM-1) — derived from real purchase history
/// (`CustomerRepository.getFavoriteProducts`, product names ranked by how
/// often they appear across a customer's recorded purchases). Renders
/// nothing at all when a customer has no purchase history yet, matching
/// `CustomerInsightsSection`'s "gracefully hide unavailable sections"
/// convention rather than a permanent empty card.
class CustomerFavoriteProductsCard extends StatelessWidget {
  const CustomerFavoriteProductsCard({required this.products, super.key});

  final List<({String name, int timesPurchased})> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Favorite Products',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < products.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: AppColors.primarySubtle, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.heart,
                      size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(products[i].name,
                      style: AppTypography.bodySM
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                  '${products[i].timesPurchased}x',
                  style:
                      AppTypography.bodySM.copyWith(color: AppColors.textGrey),
                ),
              ],
            ),
            if (i != products.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
