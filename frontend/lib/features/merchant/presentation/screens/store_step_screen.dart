import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/validators/merchant_validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../../core/widgets/text_fields/app_text_field.dart';
import 'address_step_screen.dart';

/// Store details — required. SurfPOS is in-store-only, so an onboarded
/// merchant with no store can't process payments yet (see
/// docs/08_ARCHITECTURE_DECISIONS.md § ADR-026).
class StoreStepData {
  const StoreStepData({
    required this.name,
    required this.email,
    required this.phoneCode,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.careOf,
    required this.city,
    required this.postalCode,
  });

  final String name;
  final String email;
  final String phoneCode;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String? careOf;
  final String city;
  final String postalCode;
}

/// Step 4/5 — store details. [businessAddress] backs the "same as business
/// address" checkbox — checking it copies those values in and disables the
/// address fields for editing, reducing re-entry for the common case of an
/// in-store merchant whose store is at their registered business address.
class StoreStepScreen extends StatefulWidget {
  const StoreStepScreen({
    required this.businessAddress,
    this.initialData,
    this.onNext,
    this.onBack,
    super.key,
  });

  final AddressStepData businessAddress;
  final StoreStepData? initialData;
  final ValueChanged<StoreStepData>? onNext;
  final VoidCallback? onBack;

  @override
  State<StoreStepScreen> createState() => _StoreStepScreenState();
}

class _StoreStepScreenState extends State<StoreStepScreen> {
  late final _nameController = TextEditingController(text: widget.initialData?.name ?? '');
  late final _emailController = TextEditingController(text: widget.initialData?.email ?? '');
  late final _phoneCodeController = TextEditingController(text: widget.initialData?.phoneCode ?? '');
  late final _phoneNumberController = TextEditingController(text: widget.initialData?.phoneNumber ?? '');
  late final _addressLine1Controller = TextEditingController(
    text: widget.initialData?.addressLine1 ?? (_sameAsBusinessAddress ? widget.businessAddress.addressLine1 : ''),
  );
  late final _addressLine2Controller = TextEditingController(
    text: widget.initialData?.addressLine2 ?? (_sameAsBusinessAddress ? widget.businessAddress.addressLine2 : null) ?? '',
  );
  late final _careOfController = TextEditingController(
    text: widget.initialData?.careOf ?? (_sameAsBusinessAddress ? widget.businessAddress.careOf : null) ?? '',
  );
  late final _cityController = TextEditingController(
    text: widget.initialData?.city ?? (_sameAsBusinessAddress ? widget.businessAddress.city : ''),
  );
  late final _postalCodeController = TextEditingController(
    text: widget.initialData?.postalCode ?? (_sameAsBusinessAddress ? widget.businessAddress.postalCode : ''),
  );

  late bool _sameAsBusinessAddress = widget.initialData == null;

  String? _nameError;
  String? _emailError;
  String? _phoneCodeError;
  String? _phoneNumberError;
  String? _addressLine1Error;
  String? _cityError;
  String? _postalCodeError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneCodeController.dispose();
    _phoneNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _careOfController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _handleSameAsBusinessAddressChanged(bool? value) {
    setState(() {
      _sameAsBusinessAddress = value ?? false;
      if (_sameAsBusinessAddress) {
        _addressLine1Controller.text = widget.businessAddress.addressLine1;
        _addressLine2Controller.text = widget.businessAddress.addressLine2 ?? '';
        _careOfController.text = widget.businessAddress.careOf ?? '';
        _cityController.text = widget.businessAddress.city;
        _postalCodeController.text = widget.businessAddress.postalCode;
      }
    });
  }

  void _handleNext() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneCode = _phoneCodeController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final addressLine1 = _addressLine1Controller.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    setState(() {
      _nameError = validateStoreName(name);
      _emailError = validateEmail(email);
      _phoneCodeError = validatePhoneCode(phoneCode);
      _phoneNumberError = validatePhoneNumber(phoneNumber);
      _addressLine1Error = validateAddressLine1(addressLine1);
      _cityError = validateCity(city);
      _postalCodeError = validatePostalCode(postalCode);
    });

    if ([
      _nameError,
      _emailError,
      _phoneCodeError,
      _phoneNumberError,
      _addressLine1Error,
      _cityError,
      _postalCodeError,
    ].any((error) => error != null)) {
      return;
    }

    widget.onNext?.call(
      StoreStepData(
        name: name,
        email: email,
        phoneCode: phoneCode,
        phoneNumber: phoneNumber,
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
          Text('Your store', style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A default store is created as part of onboarding so you can start accepting in-store payments.',
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Store name',
            hint: 'Main Street Store',
            leadingIcon: LucideIcons.store,
            controller: _nameController,
            errorText: _nameError,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Store email',
            hint: 'store@yourbusiness.com',
            leadingIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            errorText: _emailError,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: AppTextField(
                  label: 'Code',
                  hint: '46',
                  keyboardType: TextInputType.number,
                  controller: _phoneCodeController,
                  errorText: _phoneCodeError,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'Store phone',
                  hint: '701234567',
                  leadingIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  controller: _phoneNumberController,
                  errorText: _phoneNumberError,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            value: _sameAsBusinessAddress,
            onChanged: _handleSameAsBusinessAddressChanged,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: Text('Same as business address', style: AppTypography.bodyMD),
          ),
          AppTextField(
            label: 'Address line 1',
            hint: 'Main Street 123',
            leadingIcon: LucideIcons.mapPin,
            controller: _addressLine1Controller,
            errorText: _addressLine1Error,
            enabled: !_sameAsBusinessAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Address line 2 (optional)',
            hint: 'Building, floor, etc.',
            controller: _addressLine2Controller,
            enabled: !_sameAsBusinessAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'City',
            hint: 'Stockholm',
            controller: _cityController,
            errorText: _cityError,
            enabled: !_sameAsBusinessAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Postal code',
            hint: '123 45',
            controller: _postalCodeController,
            errorText: _postalCodeError,
            enabled: !_sameAsBusinessAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Care of (optional)',
            hint: 'Addressee accepting correspondence',
            controller: _careOfController,
            enabled: !_sameAsBusinessAddress,
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
