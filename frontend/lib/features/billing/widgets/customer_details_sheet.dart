import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/bottom_sheets/app_bottom_sheet.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../core/widgets/text_fields/app_text_field.dart';
import '../models/customer_details.dart';

/// Opens the optional "Customer" step between tapping Checkout and the
/// Payment Summary/method dialog — walk-in-friendly: collapsed by default,
/// and [Skip] is reachable in exactly one tap without ever expanding the
/// fields. Frontend-only capture, never blocks checkout (see
/// `CustomerDetails`'s own header comment for why).
Future<CustomerDetails?> showCustomerDetailsSheet(BuildContext context) {
  return showAppBottomSheet<CustomerDetails?>(
    context: context,
    title: 'Customer',
    builder: (context) => const _CustomerDetailsSheetBody(),
  );
}

class _CustomerDetailsSheetBody extends StatefulWidget {
  const _CustomerDetailsSheetBody();

  @override
  State<_CustomerDetailsSheetBody> createState() =>
      _CustomerDetailsSheetBodyState();
}

class _CustomerDetailsSheetBodyState extends State<_CustomerDetailsSheetBody> {
  bool _expanded = false;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _skip() => Navigator.of(context).pop<CustomerDetails?>(null);

  void _continue() {
    final details = CustomerDetails(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );
    Navigator.of(context)
        .pop<CustomerDetails?>(details.isEmpty ? null : details);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Attach a mobile number to send a digital receipt — totally optional.',
          style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!_expanded)
          Material(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => setState(() => _expanded = true),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(LucideIcons.userPlus,
                        size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      '+ Add Customer',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          AppTextField(
            label: 'Mobile Number',
            hint: 'Enter mobile number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            leadingIcon: LucideIcons.phone,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Customer Name',
            hint: 'Enter customer name (optional)',
            controller: _nameController,
            leadingIcon: LucideIcons.user,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(label: 'Skip', onPressed: _skip),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: AppPrimaryButton(
                  label: 'Continue to Payment', onPressed: _continue),
            ),
          ],
        ),
      ],
    );
  }
}
