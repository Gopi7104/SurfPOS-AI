import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/headers/section_header.dart';

/// One Low Stock row's plain display data — deliberately not tied to either
/// `DemoProduct` or the real `ProductModel`, so this section renders
/// identically regardless of which one the page's data came from.
typedef LowStockRow = ({String name, int remaining});

/// The Low Stock section — a stack of individual warning-toned alert
/// cards (product swatch, name, remaining-stock badge, a "Restock" quick
/// action) instead of a single dense list, so each low-stock product reads
/// as its own attention-worthy item. Real Inventory data when no demo
/// dataset is active, the generated demo catalog's own low-stock products
/// when it is.
class LowStockSection extends StatelessWidget {
  const LowStockSection({required this.rows, this.onRestock, super.key});

  final List<LowStockRow> rows;

  /// Shared across every card — jumps to Inventory, where the merchant can
  /// actually adjust stock; this section never mutates stock itself.
  final VoidCallback? onRestock;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final shown = rows.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Low Stock'),
        for (var i = 0; i < shown.length; i++) ...[
          _LowStockCard(row: shown[i], onRestock: onRestock),
          if (i != shown.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.row, this.onRestock});

  final LowStockRow row;
  final VoidCallback? onRestock;

  @override
  Widget build(BuildContext context) {
    final isOut = row.remaining == 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(LucideIcons.package,
                size: 20, color: AppColors.warning),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: AppTypography.bodyMD
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                StatusChip(
                  label: isOut ? 'Out of stock' : '${row.remaining} left',
                  tone: isOut ? StatusTone.error : StatusTone.warning,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: onRestock,
            style: OutlinedButton.styleFrom(
              // The app-wide OutlinedButtonTheme defaults to a full-width,
              // `Size.fromHeight`-based minimum (every other OutlinedButton
              // in this app fills its row) — this is an inline,
              // content-width button sitting directly in a Row, so without
              // this override it forces a taller-than-intended row and
              // fights the compact 44px icon it sits beside. Same fix as
              // `features/inventory/widgets/low_stock_section.dart`'s own
              // Quick Restock button.
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }
}
