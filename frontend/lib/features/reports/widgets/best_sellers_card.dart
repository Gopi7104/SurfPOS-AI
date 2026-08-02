import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/headers/section_header.dart';
import '../../../core/widgets/progress/app_progress_bar.dart';
import 'empty_reports_view.dart';

/// One ranked row — generic (not `TopProduct`/`DemoProduct` directly) so
/// this card doesn't depend on either model; the page converts. [category]
/// is nullable since the real `TopProduct` model has no category field
/// today — omitted gracefully rather than shown as blank text.
typedef BestSellerRow = ({
  String name,
  String? category,
  int unitsSold,
  double revenue,
  double progress,
});

/// The Best Selling Products section — the top 3 as slightly larger
/// "podium" cards with a rank badge, the rest as compact rows. [progress]
/// is already 0.0–1.0 relative-to-top-seller on every row (computed by the
/// page, the same local scaling every chart in this app already does for
/// its own axis — see `TopProduct.progress`'s own header comment).
class BestSellersCard extends StatelessWidget {
  const BestSellersCard({required this.rows, super.key});

  final List<BestSellerRow> rows;

  static const _rankColors = [
    Color(0xFFD4AF37),
    Color(0xFFA8A9AD),
    Color(0xFFCD7F32)
  ];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Best Selling Products'),
          AppCard(
              child: EmptyReportsView(
                  message: 'No products sold in this period yet.')),
        ],
      );
    }

    final top3 = rows.take(3).toList();
    final rest = rows.skip(3).take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Best Selling Products'),
        for (var i = 0; i < top3.length; i++) ...[
          _RankedTile(rank: i + 1, row: top3[i], rankColor: _rankColors[i]),
          if (i != top3.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
        for (final row in rest) ...[
          const SizedBox(height: AppSpacing.sm),
          _CompactTile(row: row),
        ],
      ],
    );
  }
}

class _RankedTile extends StatelessWidget {
  const _RankedTile(
      {required this.rank, required this.row, required this.rankColor});

  final int rank;
  final BestSellerRow row;
  final Color rankColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('#$rank',
                style: AppTypography.bodySM
                    .copyWith(color: rankColor, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name,
                    style: AppTypography.bodyMD
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                if (row.category != null) ...[
                  const SizedBox(height: 2),
                  Text(row.category!, style: AppTypography.caption),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(value: row.progress, color: rankColor),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${row.revenue.toStringAsFixed(2)}',
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${row.unitsSold} sold', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({required this.row});

  final BestSellerRow row;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(LucideIcons.package, size: 16, color: AppColors.textGrey),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(row.name,
                style: AppTypography.bodySM, overflow: TextOverflow.ellipsis),
          ),
          Text('${row.unitsSold} sold', style: AppTypography.caption),
          const SizedBox(width: AppSpacing.sm),
          Text('\$${row.revenue.toStringAsFixed(0)}',
              style:
                  AppTypography.bodySM.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
