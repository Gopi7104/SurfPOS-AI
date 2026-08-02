import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/bottom_sheets/app_bottom_sheet.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/product_model.dart';
import '../pages/add_product_page.dart';
import '../pages/edit_product_page.dart';
import '../providers/inventory_providers.dart';
import 'stock_adjustment_sheet.dart';

/// Long-press Quick Actions for a product — Edit, Duplicate, Adjust Stock,
/// Print Label (placeholder), Archive (placeholder), Delete. Every enabled
/// action reuses an existing screen/controller method verbatim; only the
/// entry point (a bottom sheet instead of navigating straight to Product
/// Details) is new.
Future<void> showProductQuickActionsSheet(
  BuildContext context, {
  required String uid,
  required ProductModel product,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: product.name,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionTile(
          icon: LucideIcons.squarePen,
          label: 'Edit',
          onTap: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => EditProductPage(product: product)),
            );
          },
        ),
        _ActionTile(
          icon: LucideIcons.copyPlus,
          label: 'Duplicate',
          onTap: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => AddProductPage(duplicateFrom: product)),
            );
          },
        ),
        _ActionTile(
          icon: LucideIcons.packagePlus,
          label: 'Adjust Stock',
          onTap: () {
            Navigator.of(sheetContext).pop();
            showStockAdjustmentSheet(context,
                uid: uid, product: product, allowNegative: true);
          },
        ),
        const _ActionTile(
          icon: LucideIcons.printer,
          label: 'Print Label',
          badge: StatusChip(label: 'Coming Soon'),
        ),
        const _ActionTile(
          icon: LucideIcons.archive,
          label: 'Archive',
          badge: StatusChip(label: 'Coming Soon'),
        ),
        _ActionTile(
          icon: LucideIcons.trash2,
          label: 'Delete',
          isDestructive: true,
          onTap: () {
            Navigator.of(sheetContext).pop();
            _confirmDelete(context, uid, product);
          },
        ),
      ],
    ),
  );
}

Future<void> _confirmDelete(
    BuildContext context, String uid, ProductModel product) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this product?'),
      content: const Text(
          'This removes it from your catalog. This cannot be undone from here.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final container = ProviderScope.containerOf(context);
  try {
    await container
        .read(inventoryListControllerProvider(uid).notifier)
        .deleteProduct(product.id);
    container.invalidate(inventoryCategoriesProvider(uid));
    container.invalidate(inventoryStatsProvider(uid));
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not delete this product. Please try again.')),
      );
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.badge,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    return ListTile(
      leading: Icon(icon, color: badge != null ? AppColors.textGrey : color),
      title: Text(label,
          style: TextStyle(color: badge != null ? AppColors.textGrey : color)),
      trailing: badge,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
