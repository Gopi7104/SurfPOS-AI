import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/bottom_sheets/app_bottom_sheet.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../core/widgets/text_fields/app_text_field.dart';
import '../../customers/models/customer_draft.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/models/customer_query.dart';
import '../../customers/providers/customer_providers.dart';
import '../models/customer_details.dart';

/// Opens the optional "Customer" step between tapping Checkout and the
/// Payment Summary/method dialog — walk-in-friendly: collapsed by default,
/// and [Skip] is reachable in exactly one tap without ever expanding the
/// fields, at every point in the flow (see `CustomerDetails`'s own header
/// comment for why this never blocks checkout).
///
/// Phase CRM-1: typing a phone number now searches the merchant's real
/// `CustomerRepository` (debounced, same 350ms idiom Billing's own product
/// search uses) — a match auto-fills name/phone and links the resulting
/// [CustomerDetails.customerId]; no match offers "Create New Customer"
/// instead. Neither path is required: a cashier can still type a plain
/// walk-in name/phone and continue with `customerId: null`, exactly as
/// before.
Future<CustomerDetails?> showCustomerDetailsSheet(
  BuildContext context, {
  required String uid,
}) {
  return showAppBottomSheet<CustomerDetails?>(
    context: context,
    title: 'Customer',
    builder: (context) => _CustomerDetailsSheetBody(uid: uid),
  );
}

class _CustomerDetailsSheetBody extends ConsumerStatefulWidget {
  const _CustomerDetailsSheetBody({required this.uid});

  final String uid;

  @override
  ConsumerState<_CustomerDetailsSheetBody> createState() =>
      _CustomerDetailsSheetBodyState();
}

class _CustomerDetailsSheetBodyState
    extends ConsumerState<_CustomerDetailsSheetBody> {
  bool _expanded = false;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  Timer? _debounce;
  bool _isSearching = false;
  List<CustomerModel> _matches = const [];
  String? _selectedCustomerId;
  bool _isCreating = false;

  @override
  void dispose() {
    _debounce?.cancel();
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
      customerId: _selectedCustomerId,
    );
    Navigator.of(context)
        .pop<CustomerDetails?>(details.isEmpty ? null : details);
  }

  void _onPhoneChanged(String value) {
    // Editing the phone after a match/create invalidates that link — the
    // cashier is now typing something new, so don't silently keep it
    // pointed at the old customer.
    if (_selectedCustomerId != null) {
      setState(() => _selectedCustomerId = null);
    }
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _matches = const [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final page = await ref
          .read(customerRepositoryProvider(widget.uid))
          .listCustomers(CustomerQuery(search: query), limit: 3);
      if (!mounted) return;
      setState(() {
        _matches = page.items;
        _isSearching = false;
      });
    } catch (_) {
      // Best-effort convenience search — a lookup failure never blocks
      // checkout, it just falls back to plain free-text entry.
      if (!mounted) return;
      setState(() {
        _matches = const [];
        _isSearching = false;
      });
    }
  }

  void _selectCustomer(CustomerModel customer) {
    _debounce?.cancel();
    setState(() {
      _selectedCustomerId = customer.id;
      _matches = const [];
      _isSearching = false;
      _nameController.text = customer.fullName;
      _phoneController.text = customer.phone;
    });
  }

  Future<void> _createNewCustomer() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _isCreating) return;

    final typedName = _nameController.text.trim();
    final nameParts =
        typedName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Walk-in';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Customer';

    setState(() => _isCreating = true);
    try {
      final created = await ref
          .read(customerRepositoryProvider(widget.uid))
          .createCustomer(CustomerDraft(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
          ));
      if (!mounted) return;
      _selectCustomer(created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created customer ${created.fullName}.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not create the customer — continuing without one.')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
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
            onChanged: _onPhoneChanged,
            suffix: _isSearching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_selectedCustomerId != null
                    ? const Icon(LucideIcons.checkCircle2,
                        size: 18, color: AppColors.success)
                    : null),
          ),
          if (_matches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ..._matches.map((customer) => _MatchRow(
                  customer: customer,
                  onTap: () => _selectCustomer(customer),
                )),
          ] else if (_selectedCustomerId == null &&
              !_isSearching &&
              _phoneController.text.trim().length >= 3) ...[
            const SizedBox(height: AppSpacing.xs),
            _CreateCustomerRow(
                isCreating: _isCreating, onTap: _createNewCustomer),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Customer Name',
            hint: 'Enter customer name (optional)',
            controller: _nameController,
            leadingIcon: LucideIcons.user,
          ),
          if (_selectedCustomerId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Linked to an existing customer record.',
              style: AppTypography.bodySM.copyWith(color: AppColors.success),
            ),
          ],
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

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.customer, required this.onTap});

  final CustomerModel customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.userCheck,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName,
                        style: AppTypography.bodyMD
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(customer.phone,
                        style: AppTypography.bodySM
                            .copyWith(color: AppColors.textGrey)),
                  ],
                ),
              ),
              const Text('Use this',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCustomerRow extends StatelessWidget {
  const _CreateCustomerRow({required this.isCreating, required this.onTap});

  final bool isCreating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondarySubtle,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: isCreating ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (isCreating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(LucideIcons.userPlus,
                    size: 18, color: AppColors.textDark),
              const SizedBox(width: AppSpacing.sm),
              const Text('No match — Create New Customer',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
