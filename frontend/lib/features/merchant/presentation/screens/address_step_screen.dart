import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/validators/merchant_validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../../core/widgets/text_fields/app_text_field.dart';

/// Organisation address — required. `countryCode` isn't collected here; the
/// business step's `country` value is reused (see
/// `merchant_onboarding_wizard_page.dart`).
class AddressStepData {
  const AddressStepData({
    required this.addressLine1,
    required this.addressLine2,
    required this.careOf,
    required this.city,
    required this.postalCode,
  });

  final String addressLine1;
  final String? addressLine2;
  final String? careOf;
  final String city;
  final String postalCode;
}

/// Step 3/5 — organisation address. Presentation-only, same conventions as
/// `LoginScreen`.
class AddressStepScreen extends StatefulWidget {
  const AddressStepScreen({
    this.initialData,
    this.onNext,
    this.onBack,
    super.key,
  });

  final AddressStepData? initialData;
  final ValueChanged<AddressStepData>? onNext;
  final VoidCallback? onBack;

  @override
  State<AddressStepScreen> createState() => _AddressStepScreenState();
}

class _AddressStepScreenState extends State<AddressStepScreen> {
  late final _addressLine1Controller = TextEditingController(text: widget.initialData?.addressLine1 ?? '');
  late final _addressLine2Controller = TextEditingController(text: widget.initialData?.addressLine2 ?? '');
  late final _careOfController = TextEditingController(text: widget.initialData?.careOf ?? '');
  late final _cityController = TextEditingController(text: widget.initialData?.city ?? '');
  late final _postalCodeController = TextEditingController(text: widget.initialData?.postalCode ?? '');

  String? _addressLine1Error;
  String? _cityError;
  String? _postalCodeError;

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _careOfController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final addressLine1 = _addressLine1Controller.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    setState(() {
      _addressLine1Error = validateAddressLine1(addressLine1);
      _cityError = validateCity(city);
      _postalCodeError = validatePostalCode(postalCode);
    });

    if (_addressLine1Error != null || _cityError != null || _postalCodeError != null) {
      return;
    }

    widget.onNext?.call(
      AddressStepData(
        addressLine1: addressLine1,
        addressLine2: _addressLine2Controller.text.trim().isEmpty ? null : _addressLine2Controller.text.trim(),
        careOf: _careOfController.text.trim().isEmpty ? null : _careOfController.text.trim(),
        city: city,
        postalCode: postalCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Business address', style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The registered address of your business.',
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Address line 1',
            hint: 'Main Street 123',
            leadingIcon: LucideIcons.mapPin,
            controller: _addressLine1Controller,
            errorText: _addressLine1Error,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Address line 2 (optional)',
            hint: 'Building, floor, etc.',
            controller: _addressLine2Controller,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'City',
            hint: 'Stockholm',
            controller: _cityController,
            errorText: _cityError,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Postal code',
            hint: '123 45',
            controller: _postalCodeController,
            errorText: _postalCodeError,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Care of (optional)',
            hint: 'Addressee accepting correspondence',
            controller: _careOfController,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(label: 'Next', onPressed: _handleNext),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(label: 'Back', onPressed: widget.onBack),
        ],
      ),
    );
  }
}
