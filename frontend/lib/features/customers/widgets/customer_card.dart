import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../models/customer_model.dart';
import '../models/customer_status.dart';
import 'customer_avatar.dart';

/// One customer row in the Customer List — every field the CRM redesign's
/// "Customer Card" section calls for: avatar, name, phone, email, last
/// purchase, lifetime spend, status, VIP badge, and member since. Same
/// data as before this redesign (see `CustomerRepositoryImpl`'s header
/// comment on which fields are real vs. currently always-zero) — only the
/// visual layout changed. [AppCard]'s own press-scale + [onTap] already
/// give this a large, animated tap target.
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
              CustomerAvatar(customer: customer, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.fullName,
                            style: AppTypography.bodyLG
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customer.isVip) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(LucideIcons.crown,
                              size: 15, color: AppColors.warning),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    _ContactLine(icon: LucideIcons.phone, text: customer.phone),
                    if (customer.email != null) ...[
                      const SizedBox(height: 2),
                      _ContactLine(
                          icon: LucideIcons.mail, text: customer.email!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: customer.status.label,
                tone: customer.status == CustomerStatus.active
                    ? StatusTone.success
                    : StatusTone.neutral,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: _StatPair(
                  label: 'Last Purchase',
                  value: customer.lastPurchaseAt == null
                      ? '—'
                      : _formatDate(customer.lastPurchaseAt!),
                ),
              ),
              Expanded(
                child: _StatPair(
                  label: 'Lifetime Spend',
                  value: '\$${customer.lifetimeSpend.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _StatPair(
                    label: 'Member Since',
                    value: _formatDate(customer.memberSince)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textGrey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
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
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
