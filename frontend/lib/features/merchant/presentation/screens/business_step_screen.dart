import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/validators/merchant_validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/text_fields/app_text_field.dart';

/// Validated output of [BusinessStepScreen] — [country] doubles as the
/// top-level Surfboard `country` field and the default country for the
/// organisation/store addresses collected in later steps (see
/// `merchant_onboarding_wizard_page.dart`), so the merchant isn't asked to
/// re-enter the same country three times.
class BusinessStepData {
  const BusinessStepData({
    required this.country,
    required this.corporateId,
    required this.legalName,
    required this.mccCode,
  });

  final String country;
  final String corporateId;
  final String? legalName;
  final String? mccCode;
}

/// Step 1/5 — business identity. Presentation-only, same conventions as
/// `LoginScreen`: self-contained controllers, feedback-only validation,
/// reports a validated result via [onNext].
class BusinessStepScreen extends StatefulWidget {
  const BusinessStepScreen({
    this.initialData,
    this.onNext,
    super.key,
  });

  final BusinessStepData? initialData;
  final ValueChanged<BusinessStepData>? onNext;

  @override
  State<BusinessStepScreen> createState() => _BusinessStepScreenState();
}

class _BusinessStepScreenState extends State<BusinessStepScreen> {
  late final _countryController = TextEditingController(text: widget.initialData?.country ?? '');
  late final _corporateIdController = TextEditingController(text: widget.initialData?.corporateId ?? '');
  late final _legalNameController = TextEditingController(text: widget.initialData?.legalName ?? '');
  late final _mccCodeController = TextEditingController(text: widget.initialData?.mccCode ?? '');

  String? _countryError;
  String? _corporateIdError;
  String? _mccCodeError;

  @override
  void dispose() {
    _countryController.dispose();
    _corporateIdController.dispose();
    _legalNameController.dispose();
    _mccCodeController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final country = _countryController.text.trim().toUpperCase();
    final corporateId = _corporateIdController.text.trim();
    final mccCode = _mccCodeController.text.trim();

    setState(() {
      _countryError = validateCountryCode(country);
      _corporateIdError = validateCorporateId(corporateId);
      _mccCodeError = validateMccCode(mccCode);
    });

    if (_countryError != null || _corporateIdError != null || _mccCodeError != null) {
      return;
    }

    widget.onNext?.call(
      BusinessStepData(
        country: country,
        corporateId: corporateId,
        legalName: _legalNameController.text.trim().isEmpty ? null : _legalNameController.text.trim(),
        mccCode: mccCode.isEmpty ? null : mccCode,
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
          Text('Business details', style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Tell us about your business — we'll use this to start your Surfboard merchant application.",
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Country',
            hint: 'SE',
            helperText: '2-letter country code',
            leadingIcon: LucideIcons.globe,
            controller: _countryController,
            errorText: _countryError,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Corporate ID',
            hint: 'Business registration number',
            leadingIcon: LucideIcons.building2,
            controller: _corporateIdController,
            errorText: _corporateIdError,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Legal name (optional)',
            hint: 'Registered legal entity name',
            leadingIcon: LucideIcons.fileText,
            controller: _legalNameController,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Merchant Category Code (optional)',
            hint: '5941',
            helperText: '4-digit MCC, if known',
            leadingIcon: LucideIcons.tag,
            keyboardType: TextInputType.number,
            controller: _mccCodeController,
            errorText: _mccCodeError,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(label: 'Next', onPressed: _handleNext),
        ],
      ),
    );
  }
}
