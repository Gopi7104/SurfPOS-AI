import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/cards/app_card.dart';
import 'add_product_page.dart';
import 'product_barcode_scanner_page.dart';

/// "Add Product" now offers a choice up front, matching a professional
/// retail POS onboarding flow: scan a barcode to auto-fill everything a
/// public product database knows, or fill in every field by hand. Manual
/// entry ([AddProductPage] with no prefill) is unchanged and always
/// available — barcode lookup is purely an additive shortcut.
class AddProductEntryPage extends StatelessWidget {
  const AddProductEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
          title: 'Add Product', onBack: () => Navigator.of(context).pop()),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How would you like to add this product?',
              style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: AppSpacing.lg),
            _EntryOptionCard(
              icon: LucideIcons.scanLine,
              title: 'Scan Barcode',
              subtitle:
                  'Auto-fill name, brand, image, and more from a product database',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ProductBarcodeScannerPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _EntryOptionCard(
              icon: LucideIcons.penLine,
              title: 'Enter Manually',
              subtitle: 'Fill in every product detail yourself',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryOptionCard extends StatelessWidget {
  const _EntryOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headingSM),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.bodySM
                        .copyWith(color: AppColors.textGrey)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.textGrey),
        ],
      ),
    );
  }
}
