import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/validators/merchant_validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../../core/widgets/text_fields/app_text_field.dart';

/// Organisation-level contact details — all optional on the wire (Surfboard
/// only requires them for PF partners), so every field may be `null`.
class ContactStepData {
  const ContactStepData({this.email, this.phoneCode, this.phoneNumber});

  final String? email;
  final String? phoneCode;
  final String? phoneNumber;
}

/// Step 2/5 — organisation contact (optional). Presentation-only, same
/// conventions as `LoginScreen`.
class ContactStepScreen extends StatefulWidget {
  const ContactStepScreen({
    this.initialData,
    this.onNext,
    this.onBack,
    super.key,
  });

  final ContactStepData? initialData;
  final ValueChanged<ContactStepData>? onNext;
  final VoidCallback? onBack;

  @override
  State<ContactStepScreen> createState() => _ContactStepScreenState();
}

class _ContactStepScreenState extends State<ContactStepScreen> {
  late final _emailController =
      TextEditingController(text: widget.initialData?.email ?? '');
  late final _phoneCodeController =
      TextEditingController(text: widget.initialData?.phoneCode ?? '');
  late final _phoneNumberController =
      TextEditingController(text: widget.initialData?.phoneNumber ?? '');

  String? _emailError;
  String? _phoneCodeError;
  String? _phoneNumberError;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneCodeController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final email = _emailController.text.trim();
    final phoneCode = _phoneCodeController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final anyPhoneEntered = phoneCode.isNotEmpty || phoneNumber.isNotEmpty;

    setState(() {
      _emailError = email.isEmpty ? null : validateEmail(email);
      // If either phone field was started, both are required together —
      // Surfboard's phoneNumber is a single object, not two independent
      // optional values.
      _phoneCodeError = anyPhoneEntered ? validatePhoneCode(phoneCode) : null;
      _phoneNumberError =
          anyPhoneEntered ? validatePhoneNumber(phoneNumber) : null;
    });

    if (_emailError != null ||
        _phoneCodeError != null ||
        _phoneNumberError != null) {
      return;
    }

    widget.onNext?.call(
      ContactStepData(
        email: email.isEmpty ? null : email,
        phoneCode: anyPhoneEntered ? phoneCode : null,
        phoneNumber: anyPhoneEntered ? phoneNumber : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Business contact', style: AppTypography.headingMD),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Optional — only required for some partner types, but useful for Surfboard to reach your business.',
            style: AppTypography.bodySM.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Business email (optional)',
            hint: 'contact@yourbusiness.com',
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
                  label: 'Business phone (optional)',
                  hint: '701234567',
                  leadingIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  controller: _phoneNumberController,
                  errorText: _phoneNumberError,
                ),
              ),
            ],
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
