import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../authentication/providers/auth_providers.dart';
import '../../data/models/merchant_application.dart';
import '../../domain/merchant_onboarding_failure.dart';
import '../providers/merchant_onboarding_providers.dart';
import 'address_step_screen.dart';
import 'business_step_screen.dart';
import 'contact_step_screen.dart';
import 'result_step_screen.dart';
import 'review_step_screen.dart';
import 'store_step_screen.dart';

const _stepCount = 5;

/// Riverpod wrapper + wizard-step orchestrator for Merchant Onboarding —
/// owns step navigation, accumulated form data across steps, and all
/// submission-state wiring, mirroring the Screen(dumb)/Page(Riverpod-aware)
/// split used throughout `features/authentication/` scaled to a multi-step
/// flow. If an application already exists (restored from cache or just
/// submitted), shows [ResultStepScreen] instead of the input steps — only
/// one application is ever allowed per account (see
/// docs/08_ARCHITECTURE_DECISIONS.md § ADR-021).
class MerchantOnboardingWizardPage extends ConsumerStatefulWidget {
  const MerchantOnboardingWizardPage({super.key});

  @override
  ConsumerState<MerchantOnboardingWizardPage> createState() =>
      _MerchantOnboardingWizardPageState();
}

class _MerchantOnboardingWizardPageState
    extends ConsumerState<MerchantOnboardingWizardPage> {
  int _currentStep = 0;

  BusinessStepData? _business;
  ContactStepData? _contact;
  AddressStepData? _address;
  StoreStepData? _store;

  void _goToStep(int step) => setState(() => _currentStep = step);

  void _handleSubmit() {
    final business = _business!;
    final contact = _contact!;
    final address = _address!;
    final store = _store!;
    final uid = ref.read(authControllerProvider).valueOrNull!.uid;

    ref.read(merchantOnboardingControllerProvider(uid).notifier).submit(
          country: business.country,
          corporateId: business.corporateId,
          legalName: business.legalName,
          mccCode: business.mccCode,
          organisationAddressLine1: address.addressLine1,
          organisationAddressLine2: address.addressLine2,
          organisationCareOf: address.careOf,
          organisationCity: address.city,
          organisationCountryCode: business.country,
          organisationPostalCode: address.postalCode,
          organisationPhoneCode: contact.phoneCode,
          organisationPhoneNumber: contact.phoneNumber,
          organisationEmail: contact.email,
          storeName: store.name,
          storeEmail: store.email,
          storePhoneCode: store.phoneCode,
          storePhoneNumber: store.phoneNumber,
          storeAddressLine1: store.addressLine1,
          storeAddressLine2: store.addressLine2,
          storeCareOf: store.careOf,
          storeCity: store.city,
          storeCountryCode: business.country,
          storePostalCode: store.postalCode,
        );
  }

  // Deliberately does not gate on canLaunchUrl() first — on Android, canLaunchUrl relies on
  // PackageManager.resolveActivity, which package-visibility restrictions (Android 11+) can make
  // return a false negative even when a browser is installed and launchUrl() itself would succeed
  // (confirmed via device logcat: AppsFilter BLOCKED the app's *query* for Chrome, while launching
  // Chrome directly via an implicit ACTION_VIEW intent is not subject to the same restriction).
  // launchUrl()'s own boolean return + a try/catch is the actual signal to trust here.
  Future<void> _handleOpenKybLink(String url) async {
    final uri = Uri.parse(url);
    debugPrint(
      '[MerchantOnboarding] Opening KYB link — raw: $url | scheme: ${uri.scheme} | host: ${uri.host}',
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('[MerchantOnboarding] launchUrl threw: $error');
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open the link. Try copying it instead.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keyed by uid — a different signed-in account gets a completely separate controller
    // instance, so this screen can never render another account's cached application.
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = merchantOnboardingControllerProvider(uid);
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Merchant Onboarding', style: AppTypography.headingSM),
      ),
      body: SafeArea(
        child: switch (state) {
          AsyncLoading() when !state.hasValue =>
            const Center(child: CircularProgressIndicator()),
          AsyncData(value: final application?) => ResultStepScreen(
              application: application,
              isRefreshing: state.isLoading,
              onRefresh: () => ref.read(provider.notifier).refreshStatus(),
              onOpenKybLink: _handleOpenKybLink,
            ),
          _ => _buildWizard(state),
        },
      ),
    );
  }

  Widget _buildWizard(AsyncValue<MerchantApplication?> state) {
    return Column(
      children: [
        _StepProgress(currentStep: _currentStep, stepCount: _stepCount),
        Expanded(
          child: switch (_currentStep) {
            0 => BusinessStepScreen(
                initialData: _business,
                onNext: (data) {
                  setState(() => _business = data);
                  _goToStep(1);
                },
              ),
            1 => ContactStepScreen(
                initialData: _contact,
                onNext: (data) {
                  setState(() => _contact = data);
                  _goToStep(2);
                },
                onBack: () => _goToStep(0),
              ),
            2 => AddressStepScreen(
                initialData: _address,
                onNext: (data) {
                  setState(() => _address = data);
                  _goToStep(3);
                },
                onBack: () => _goToStep(1),
              ),
            3 => StoreStepScreen(
                businessAddress: _address!,
                initialData: _store,
                onNext: (data) {
                  setState(() => _store = data);
                  _goToStep(4);
                },
                onBack: () => _goToStep(2),
              ),
            _ => ReviewStepScreen(
                business: _business!,
                contact: _contact!,
                address: _address!,
                store: _store!,
                isLoading: state.isLoading,
                errorMessage: state.hasError
                    ? MerchantOnboardingFailure.fromException(state.error!)
                        .message
                    : null,
                onSubmit: _handleSubmit,
                onBack: () => _goToStep(3),
              ),
          },
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep, required this.stepCount});

  final int currentStep;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentStep + 1} of $stepCount',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / stepCount,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
