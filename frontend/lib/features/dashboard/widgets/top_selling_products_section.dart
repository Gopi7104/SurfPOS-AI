import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../demo_data/models/demo_product.dart';

/// The Top Selling Products section — a horizontal row of compact cards
/// (image/color swatch, name, units sold, revenue) rather than a full-width
/// list, so 5 products fit without a large vertical block — "avoid large
/// empty spaces" from the design brief.
class TopSellingProductsSection extends StatelessWidget {
  const TopSellingProductsSection({required this.products, super.key});

  final List<DemoProduct> products;

  static const _swatchPalette = [
    AppColors.primary,
    AppColors.primaryLight,
    AppColors.success,
    AppColors.warning,
    AppColors.primaryDark,
  ];

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Top Selling Products'),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 132,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _swatchPalette[
                                  product.colorSeed % _swatchPalette.length]
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(LucideIcons.package,
                            color: _swatchPalette[
                                product.colorSeed % _swatchPalette.length],
                            size: 24),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        product.name,
                        style: AppTypography.bodySM
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('${product.unitsSold} units',
                          style: AppTypography.caption),
                      const SizedBox(height: 2),
                      Text(
                        '\$${product.revenue.toStringAsFixed(0)}',
                        style: AppTypography.bodySM.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
