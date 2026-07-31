import 'package:flutter/material.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../../core/widgets/dialogs/error_banner.dart';
import 'address_step_screen.dart';
import 'business_step_screen.dart';
import 'contact_step_screen.dart';
import 'store_step_screen.dart';

/// Step 5/5 — review everything collected across the previous 4 steps
/// before submitting. Presentation-only; [isLoading]/[errorMessage] are
/// controlled by the caller (same convention as `LoginScreen`).
class ReviewStepScreen extends StatelessWidget {
  const ReviewStepScreen({
    required this.business,
    required this.contact,
    required this.address,
    required this.store,
    this.onSubmit,
    this.onBack,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final BusinessStepData business;
  final ContactStepData contact;
  final AddressStepData address;
  final StoreStepData store;
  final VoidCallback? onSubmit;
  final VoidCallback? onBack;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Review & submit', style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Double-check your details — you'll receive a link to complete verification after submitting.",
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (errorMessage != null) ...[
            ErrorBanner(message: errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          _Section(
            title: 'Business',
            rows: {
              'Country': business.country,
              'Corporate ID': business.corporateId,
              if (business.legalName != null) 'Legal name': business.legalName!,
              if (business.mccCode != null) 'MCC': business.mccCode!,
            },
          ),
          if (contact.email != null || contact.phoneNumber != null)
            _Section(
              title: 'Contact',
              rows: {
                if (contact.email != null) 'Email': contact.email!,
                if (contact.phoneNumber != null)
                  'Phone': '+${contact.phoneCode} ${contact.phoneNumber}',
              },
            ),
          _Section(
            title: 'Business address',
            rows: {
              'Address': address.addressLine1,
              if (address.addressLine2 != null) '': address.addressLine2!,
              'City': address.city,
              'Postal code': address.postalCode,
            },
          ),
          _Section(
            title: 'Store',
            rows: {
              'Name': store.name,
              'Email': store.email,
              'Phone': '+${store.phoneCode} ${store.phoneNumber}',
              'Address': store.addressLine1,
              if (store.addressLine2 != null) '': store.addressLine2!,
              'City': store.city,
              'Postal code': store.postalCode,
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Submit application',
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
              label: 'Back', onPressed: isLoading ? null : onBack),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingSM),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in rows.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                entry.key.isEmpty
                    ? entry.value
                    : '${entry.key}: ${entry.value}',
                style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
              ),
            ),
        ],
      ),
    );
  }
}
