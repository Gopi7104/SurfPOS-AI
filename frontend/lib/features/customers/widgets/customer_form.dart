import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/text_fields/app_text_field.dart';
import '../models/customer_draft.dart';
import '../models/customer_model.dart';
import '../models/customer_tag.dart';

const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

/// Shared Add/Edit Customer form body — same conventions as `ProductForm`:
/// self-contained controllers, feedback-only validation, reports a
/// validated [CustomerDraft] via [onSubmit]. [initial] pre-fills every
/// field for Edit; omitted (null) for Add.
///
/// The Notes field only appears in Add mode — it only ever seeds the
/// customer's first [CustomerNote] (see [CustomerDraft.initialNote]'s
/// header comment); editing notes afterwards goes through Customer
/// Details' "Add Note" action instead, since a note is a timestamped
/// timeline entry, not a single editable field.
class CustomerForm extends StatefulWidget {
  const CustomerForm({
    this.initial,
    required this.onSubmit,
    this.isSubmitting = false,
    this.errorMessage,
    this.submitLabel = 'Save',
    super.key,
  });

  final CustomerModel? initial;
  final ValueChanged<CustomerDraft> onSubmit;
  final bool isSubmitting;
  final String? errorMessage;
  final String submitLabel;

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  late final _firstNameController =
      TextEditingController(text: widget.initial?.firstName ?? '');
  late final _lastNameController =
      TextEditingController(text: widget.initial?.lastName ?? '');
  late final _phoneController =
      TextEditingController(text: widget.initial?.phone ?? '');
  late final _emailController =
      TextEditingController(text: widget.initial?.email ?? '');
  late final _addressController =
      TextEditingController(text: widget.initial?.address ?? '');
  late final _cityController =
      TextEditingController(text: widget.initial?.city ?? '');
  late final _postalCodeController =
      TextEditingController(text: widget.initial?.postalCode ?? '');
  late final _countryController =
      TextEditingController(text: widget.initial?.country ?? '');
  late final _companyController =
      TextEditingController(text: widget.initial?.company ?? '');
  late final _vatNumberController =
      TextEditingController(text: widget.initial?.vatNumber ?? '');
  late final _noteController = TextEditingController();

  late final _dobController = TextEditingController(
    text: widget.initial?.dateOfBirth == null
        ? ''
        : _formatDate(widget.initial!.dateOfBirth!),
  );
  late DateTime? _dateOfBirth = widget.initial?.dateOfBirth;
  late String? _gender = widget.initial?.gender;
  final List<String> _tags = [];
  final _customTagController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _tags.addAll(widget.initial?.tags ?? const []);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _companyController.dispose();
    _vatNumberController.dispose();
    _dobController.dispose();
    _noteController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = _formatDate(picked);
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _customTagController.clear();
    });
  }

  String? _orNull(String text) => text.trim().isEmpty ? null : text.trim();

  void _handleSubmit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _firstNameError = firstName.isEmpty ? 'First name is required' : null;
      _lastNameError = lastName.isEmpty ? 'Last name is required' : null;
      _phoneError = phone.isEmpty ? 'Phone number is required' : null;
    });

    if ([_firstNameError, _lastNameError, _phoneError]
        .any((error) => error != null)) {
      return;
    }

    widget.onSubmit(
      CustomerDraft(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: _orNull(_emailController.text),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        address: _orNull(_addressController.text),
        city: _orNull(_cityController.text),
        postalCode: _orNull(_postalCodeController.text),
        country: _orNull(_countryController.text),
        company: _orNull(_companyController.text),
        vatNumber: _orNull(_vatNumberController.text),
        initialNote:
            widget.initial == null ? _orNull(_noteController.text) : null,
        tags: _tags,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                  label: 'First Name',
                  controller: _firstNameController,
                  errorText: _firstNameError),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  errorText: _lastNameError),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Phone',
          controller: _phoneController,
          errorText: _phoneError,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Email',
          hint: 'Optional',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: _pickDateOfBirth,
          child: AbsorbPointer(
            child: AppTextField(
              label: 'Date of Birth',
              hint: 'Optional',
              controller: _dobController,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Gender',
            style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs + 2),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final gender in _genders)
              _SelectableChip(
                label: gender,
                selected: _gender == gender,
                onSelected: () =>
                    setState(() => _gender = _gender == gender ? null : gender),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Address',
          hint: 'Optional',
          controller: _addressController,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                  label: 'City', hint: 'Optional', controller: _cityController),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                  label: 'Postal Code',
                  hint: 'Optional',
                  controller: _postalCodeController),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Country',
          hint: 'Optional',
          controller: _countryController,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Optional Details', style: AppTypography.headingSM),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Company',
          hint: 'Optional',
          controller: _companyController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'VAT Number',
          hint: 'Optional',
          controller: _vatNumberController,
        ),
        if (!isEdit) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Notes',
            hint: 'Optional — internal, never shown to the customer',
            controller: _noteController,
            maxLines: 3,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('Tags',
            style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs + 2),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final tag in {...CustomerTags.presets, ..._tags})
              _SelectableChip(
                label: tag,
                selected: _tags.contains(tag),
                onSelected: () => _toggleTag(tag),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                hint: 'Add a custom tag',
                controller: _customTagController,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(onPressed: _addCustomTag, child: const Text('Add')),
          ],
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.errorMessage!,
            style: AppTypography.bodySM.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: widget.submitLabel,
          isLoading: widget.isSubmitting,
          onPressed: widget.isSubmitting ? null : _handleSubmit,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip(
      {required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: StatusChip(
        label: label,
        tone: selected ? StatusTone.success : StatusTone.neutral,
      ),
    );
  }
}
