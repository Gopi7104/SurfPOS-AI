import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/customer_model.dart';
import '../models/customer_status.dart';
import 'customer_avatar.dart';

/// One customer row in the Customer List — every field the spec's
/// "Customer Card" section calls for: avatar, name, phone, email,
/// customer id, member since, lifetime spend, total orders, last
/// purchase, loyalty points, and status.
class CustomerCard extends StatelessWidget {
  const CustomerCard({required this.customer, this.onTap, super.key});

  final CustomerModel customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerAvatar(customer: customer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName,
                        style: AppTypography.bodyLG
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(customer.phone, style: AppTypography.caption),
                    if (customer.email != null)
                      Text(customer.email!, style: AppTypography.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(
                    label: customer.status.label,
                    tone: customer.status == CustomerStatus.active
                        ? StatusTone.success
                        : StatusTone.neutral,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(customer.id, style: AppTypography.caption),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _StatPair(
                  label: 'Member Since',
                  value: _formatDate(customer.memberSince)),
              _StatPair(
                  label: 'Lifetime Spend',
                  value: '\$${customer.lifetimeSpend.toStringAsFixed(2)}'),
              _StatPair(
                  label: 'Total Orders', value: '${customer.totalOrders}'),
              _StatPair(
                label: 'Last Purchase',
                value: customer.lastPurchaseAt == null
                    ? '—'
                    : _formatDate(customer.lastPurchaseAt!),
              ),
              _StatPair(
                  label: 'Loyalty Points', value: '${customer.loyaltyPoints}'),
            ],
          ),
          if (customer.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
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
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _StatPair extends StatelessWidget {
  const _StatPair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.caption),
        Text(value,
            style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
