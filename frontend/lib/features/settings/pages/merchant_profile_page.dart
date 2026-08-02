import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/app_bars/app_top_bar.dart';
import '../../../core/widgets/chips/status_chip.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../dashboard/models/dashboard_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/merchant_profile_draft.dart';
import '../providers/settings_providers.dart';
import '../widgets/bottom_sheet_editor.dart';
import '../widgets/editable_info_card.dart';
import '../widgets/status_badge.dart';

/// Merchant Profile — a hero block (logo, merchant/store name, status)
/// over a stack of [EditableInfoCard]s, each opening a single-field
/// [BottomSheetEditor] rather than one giant form. See
/// [MerchantProfileDraft]'s header comment for why editing here is
/// local-only, never a write back to Surfboard.
class MerchantProfilePage extends ConsumerWidget {
  const MerchantProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    final settingsAsync = ref.watch(settingsControllerProvider(uid));
    final dashboard = ref.watch(dashboardControllerProvider(uid)).valueOrNull;

    return Scaffold(
      appBar: AppTopBar(
          title: 'Merchant Profile', onBack: () => Navigator.of(context).pop()),
      body: switch (settingsAsync) {
        AsyncLoading() when !settingsAsync.hasValue =>
          const Center(child: AppLoadingIndicator()),
        _ => _MerchantProfileBody(
            uid: uid,
            profile: settingsAsync.valueOrNull?.merchantProfile ??
                const MerchantProfileDraft(),
            dashboard: dashboard,
          ),
      },
    );
  }
}

class _MerchantProfileBody extends ConsumerWidget {
  const _MerchantProfileBody({
    required this.uid,
    required this.profile,
    required this.dashboard,
  });

  final String uid;
  final MerchantProfileDraft profile;
  final DashboardState? dashboard;

  Future<void> _pickLogo(WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await ref
        .read(settingsControllerProvider(uid).notifier)
        .updateMerchantProfile(profile.copyWith(logoPath: picked.path));
  }

  void _editField(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    String? initialValue,
    String? hint,
    TextInputType? keyboardType,
    required MerchantProfileDraft Function(String?) apply,
  }) {
    showTextFieldEditorSheet(
      context,
      title: title,
      initialValue: initialValue,
      hint: hint,
      keyboardType: keyboardType,
      onSave: (value) => ref
          .read(settingsControllerProvider(uid).notifier)
          .updateMerchantProfile(apply(value)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantName =
        dashboard?.merchant?.name ?? profile.businessName ?? 'Merchant';
    final storeName = dashboard?.store?.name;
    final storeStatus = dashboard?.store?.status;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickLogo(ref),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: profile.logoPath == null
                      ? const Icon(Icons.storefront_rounded,
                          color: AppColors.primary, size: 32)
                      : Image.file(File(profile.logoPath!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(merchantName, style: AppTypography.headingSM),
              if (storeName != null) ...[
                const SizedBox(height: 2),
                Text(storeName,
                    style: AppTypography.bodySM
                        .copyWith(color: AppColors.textGrey)),
              ],
              if (storeStatus != null) ...[
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(
                  label: storeStatus,
                  tone: storeStatus.toLowerCase().contains('active')
                      ? StatusTone.success
                      : StatusTone.neutral,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'These fields are saved on this device only — they annotate your '
          'profile locally and never change your live Surfboard merchant record.',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        EditableInfoCard(
          label: 'Business Name',
          value: profile.businessName ?? 'Not set',
          icon: LucideIcons.building2,
          onEdit: () => _editField(context, ref,
              title: 'Business Name',
              initialValue: profile.businessName,
              apply: (v) => MerchantProfileDraft(
                  businessName: v,
                  contactEmail: profile.contactEmail,
                  phone: profile.phone,
                  logoPath: profile.logoPath,
                  address: profile.address,
                  country: profile.country,
                  taxNumber: profile.taxNumber,
                  businessType: profile.businessType)),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditableInfoCard(
          label: 'Email',
          value: profile.contactEmail ?? 'Not set',
          icon: LucideIcons.mail,
          onEdit: () => _editField(context, ref,
              title: 'Contact Email',
              initialValue: profile.contactEmail,
              keyboardType: TextInputType.emailAddress,
              apply: (v) => MerchantProfileDraft(
                  businessName: profile.businessName,
                  contactEmail: v,
                  phone: profile.phone,
                  logoPath: profile.logoPath,
                  address: profile.address,
                  country: profile.country,
                  taxNumber: profile.taxNumber,
                  businessType: profile.businessType)),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditableInfoCard(
          label: 'Phone',
          value: profile.phone ?? 'Not set',
          icon: LucideIcons.phone,
          onEdit: () => _editField(context, ref,
              title: 'Phone',
              initialValue: profile.phone,
              keyboardType: TextInputType.phone,
              apply: (v) => MerchantProfileDraft(
                  businessName: profile.businessName,
                  contactEmail: profile.contactEmail,
                  phone: v,
                  logoPath: profile.logoPath,
                  address: profile.address,
                  country: profile.country,
                  taxNumber: profile.taxNumber,
                  businessType: profile.businessType)),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditableInfoCard(
          label: 'Address',
          value: profile.address ?? 'Not set',
          icon: LucideIcons.mapPin,
          onEdit: () => _editField(context, ref,
              title: 'Address',
              initialValue: profile.address,
              apply: (v) => MerchantProfileDraft(
                  businessName: profile.businessName,
                  contactEmail: profile.contactEmail,
                  phone: profile.phone,
                  logoPath: profile.logoPath,
                  address: v,
                  country: profile.country,
                  taxNumber: profile.taxNumber,
                  businessType: profile.businessType)),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditableInfoCard(
          label: 'Country',
          value: profile.country ?? 'Not set',
          icon: LucideIcons.globe,
          onEdit: () => _editField(context, ref,
              title: 'Country',
              initialValue: profile.country,
              apply: (v) => MerchantProfileDraft(
                  businessName: profile.businessName,
                  contactEmail: profile.contactEmail,
                  phone: profile.phone,
                  logoPath: profile.logoPath,
                  address: profile.address,
                  country: v,
                  taxNumber: profile.taxNumber,
                  businessType: profile.businessType)),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditableInfoCard(
          label: 'Tax Number',
          value: profile.taxNumber ?? 'Not set',
          icon: LucideIcons.receipt,
          onEdit: () => _editField(context, ref,
              title: 'Tax Number',
              initialValue: profile.taxNumber,
              apply: (v) => MerchantProfileDraft(
                  businessName: profile.businessName,
                  contactEmail: profile.contactEmail,
                  phone: profile.phone,
                  logoPath: profile.logoPath,
                  address: profile.address,
                  country: profile.country,
                  taxNumber: v,
                  businessType: profile.businessType)),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditableInfoCard(
          label: 'Business Type',
          value: profile.businessType ?? 'Not set',
          icon: LucideIcons.briefcase,
          onEdit: () => _editField(context, ref,
              title: 'Business Type',
              initialValue: profile.businessType,
              apply: (v) => MerchantProfileDraft(
                  businessName: profile.businessName,
                  contactEmail: profile.contactEmail,
                  phone: profile.phone,
                  logoPath: profile.logoPath,
                  address: profile.address,
                  country: profile.country,
                  taxNumber: profile.taxNumber,
                  businessType: v)),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
