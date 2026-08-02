import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../models/customer_model.dart';
import '../models/customer_note.dart';
import '../models/customer_purchase.dart';
import '../models/customer_status.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_avatar.dart';
import '../widgets/customer_empty_state.dart';
import '../widgets/customer_info_section.dart';
import '../widgets/customer_summary_card.dart';
import '../widgets/purchase_history_tile.dart';
import 'edit_customer_page.dart';
import 'purchase_history_page.dart';

/// Customer Details — Profile, Loyalty, Purchase History (a preview —
/// "View All" opens [PurchaseHistoryPage]), Favourite Products, Payment
/// Methods, Notes, and Tags, plus Edit/soft-delete actions. Mirrors
/// `ProductDetailsPage`'s shape.
///
/// "Receipts" (the spec's own separate line item) isn't a second list —
/// every [CustomerPurchase] already carries its own receipt number, so
/// Purchase History *is* the receipts list; a second, identical section
/// would just repeat the same (currently always-empty) rows twice.
class CustomerDetailsPage extends ConsumerWidget {
  const CustomerDetailsPage({required this.customerId, super.key});

  final String customerId;

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this customer?'),
        content: const Text(
            'This removes them from your customer list. This cannot be undone from here.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(customerListControllerProvider(uid).notifier)
          .deleteCustomer(customerId);
      ref.invalidate(customerStatsProvider(uid));
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not delete this customer. Please try again.')),
        );
      }
    }
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref, String uid,
      CustomerDetailsKey key) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Internal note'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;

    await ref.read(customerRepositoryProvider(uid)).addNote(customerId, text);
    ref.invalidate(customerDetailsProvider(key));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final key = (uid: uid, customerId: customerId);
    final customerAsync = ref.watch(customerDetailsProvider(key));
    final purchasesAsync = ref.watch(customerPurchaseHistoryProvider(key));

    return Scaffold(
      appBar: AppTopBar(
          title: 'Customer Details', onBack: () => Navigator.of(context).pop()),
      body: switch (customerAsync) {
        AsyncLoading() when !customerAsync.hasValue =>
          const Center(child: AppLoadingIndicator()),
        AsyncError() when !customerAsync.hasValue => ErrorState(
            message: 'Could not load this customer.',
            onRetry: () => ref.invalidate(customerDetailsProvider(key)),
          ),
        _ => _CustomerDetailsBody(
            customer: customerAsync.value!,
            recentPurchases: purchasesAsync.valueOrNull ?? const [],
            onEdit: () async {
              final updated = await Navigator.of(context).push<CustomerModel>(
                MaterialPageRoute(
                    builder: (_) =>
                        EditCustomerPage(customer: customerAsync.value!)),
              );
              if (updated != null) ref.invalidate(customerDetailsProvider(key));
            },
            onDelete: () => _confirmDelete(context, ref, uid),
            onAddNote: () => _addNote(context, ref, uid, key),
            onViewAllPurchases: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => PurchaseHistoryPage(customerId: customerId)),
            ),
          ),
      },
    );
  }
}

class _CustomerDetailsBody extends StatelessWidget {
  const _CustomerDetailsBody({
    required this.customer,
    required this.recentPurchases,
    required this.onEdit,
    required this.onDelete,
    required this.onAddNote,
    required this.onViewAllPurchases,
  });

  final CustomerModel customer;
  final List<CustomerPurchase> recentPurchases;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddNote;
  final VoidCallback onViewAllPurchases;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerAvatar(customer: customer, size: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName, style: AppTypography.headingSM),
                    const SizedBox(height: 2),
                    Text(customer.phone, style: AppTypography.bodySM),
                    if (customer.email != null)
                      Text(customer.email!, style: AppTypography.bodySM),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusChip(
                          label: customer.status.label,
                          tone: customer.status == CustomerStatus.active
                              ? StatusTone.success
                              : StatusTone.neutral,
                        ),
                        StatusChip(
                            label: customer.membershipTier.label,
                            tone: StatusTone.warning),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.0,
          children: [
            CustomerSummaryCard(
                label: 'Lifetime Spend',
                value: '\$${customer.lifetimeSpend.toStringAsFixed(2)}',
                icon: LucideIcons.dollarSign),
            CustomerSummaryCard(
                label: 'Total Orders',
                value: '${customer.totalOrders}',
                icon: LucideIcons.shoppingBag),
            CustomerSummaryCard(
                label: 'Avg. Order Value',
                value: '\$${customer.averageOrderValue.toStringAsFixed(2)}',
                icon: LucideIcons.calculator),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        CustomerInfoSection(title: 'Profile', rows: [
          ('Customer ID', customer.id),
          (
            'Date of Birth',
            customer.dateOfBirth == null
                ? null
                : _formatDate(customer.dateOfBirth!)
          ),
          ('Gender', customer.gender),
          ('Member Since', _formatDate(customer.memberSince)),
          (
            'Last Purchase',
            customer.lastPurchaseAt == null
                ? null
                : _formatDate(customer.lastPurchaseAt!)
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        CustomerInfoSection(title: 'Address', rows: [
          ('Address', customer.address),
          ('City', customer.city),
          ('Postal Code', customer.postalCode),
          ('Country', customer.country),
        ]),
        if (customer.company != null || customer.vatNumber != null) ...[
          const SizedBox(height: AppSpacing.md),
          CustomerInfoSection(title: 'Business', rows: [
            ('Company', customer.company),
            ('VAT Number', customer.vatNumber),
          ]),
        ],
        const SizedBox(height: AppSpacing.md),
        CustomerInfoSection(title: 'Loyalty', rows: [
          ('Current Points', '${customer.loyaltyPoints}'),
          ('Lifetime Points', '${customer.lifetimePoints}'),
          ('Membership Tier', customer.membershipTier.label),
        ]),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Tags',
          child: customer.tags.isEmpty
              ? Text('No tags yet.', style: AppTypography.bodySM)
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in customer.tags)
                      StatusChip(
                          label: tag,
                          tone: tag == 'VIP'
                              ? StatusTone.warning
                              : StatusTone.neutral),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionCard(
          title: 'Favourite Products',
          child: CustomerEmptyState(
            icon: LucideIcons.heart,
            title: 'Nothing yet',
            message: 'No purchases recorded yet to learn favourites from.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionCard(
          title: 'Payment Methods',
          child: CustomerEmptyState(
            icon: LucideIcons.creditCard,
            title: 'Nothing yet',
            message: 'No saved payment methods for this customer.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Notes',
          trailing:
              TextButton(onPressed: onAddNote, child: const Text('Add Note')),
          child: customer.notes.isEmpty
              ? Text('No notes yet.', style: AppTypography.bodySM)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final note in customer.notes.reversed)
                      _NoteRow(note: note),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Purchase History',
          trailing: TextButton(
              onPressed: onViewAllPurchases, child: const Text('View All')),
          child: recentPurchases.isEmpty
              ? const CustomerEmptyState(
                  icon: LucideIcons.receipt,
                  title: 'No purchases yet',
                  message: 'Completed purchases will show up here.',
                )
              : Column(
                  children: [
                    for (final purchase in recentPurchases.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PurchaseHistoryTile(purchase: purchase),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(label: 'Edit Customer', onPressed: onEdit),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Delete Customer'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final CustomerNote note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.text, style: AppTypography.bodySM),
          const SizedBox(height: 2),
          Text(_formatDateTime(note.createdAt), style: AppTypography.caption),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
