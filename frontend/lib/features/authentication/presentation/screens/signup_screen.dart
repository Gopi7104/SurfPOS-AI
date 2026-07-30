import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/widgets/branding/surfboard_logo.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/buttons/app_secondary_button.dart';
import '../../../../core/widgets/dialogs/error_banner.dart';
import '../../../../core/widgets/text_fields/app_text_field.dart';

/// Signup screen — presentation-only, mirrors [LoginScreen]'s pattern
/// exactly (see docs/07_CODING_RULES.md § 8: screens hold no business
/// logic, only local field-level validation feedback). [isLoading] and
/// [errorMessage] are controlled by the caller (`SignupPage`).
///
/// The Google "G" mark isn't an asset in this project (no official brand
/// asset has been supplied, same situation the Surfboard logo was in before
/// it existed) — [LucideIcons.globe] is a neutral placeholder. Google's
/// brand guidelines require their official mark before shipping; swap this
/// out once that asset is available (see the Final Report's packaging note).
class SignupScreen extends StatefulWidget {
  const SignupScreen({
    this.onSignUp,
    this.onGoogleSignIn,
    this.onLogin,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  /// [mobileNumber] is `null` when left blank — it is captured here per the
  /// design brief but the backend's signup schema has no phone field yet,
  /// so the caller intentionally does not forward it (see
  /// `AuthRepositoryImpl.signUp`'s doc comment).
  final void Function(
    String fullName,
    String email,
    String? mobileNumber,
    String password,
  )? onSignUp;

  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onLogin;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _fullNameError = validateFullName(fullName);
      _emailError = validateEmail(email);
      _passwordError = validateSignupPassword(password);
      _confirmPasswordError =
          validateConfirmPassword(password, confirmPassword);
    });

    if (_fullNameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    widget.onSignUp
        ?.call(fullName, email, mobile.isEmpty ? null : mobile, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const Center(child: SurfboardLogo.badge(size: 64)),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Create your account',
                textAlign: TextAlign.center,
                style: AppTypography.headingLG,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Set up SurfPOS AI for your store',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (widget.errorMessage != null) ...[
                ErrorBanner(message: widget.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                label: 'Full Name',
                hint: 'Jane Doe',
                leadingIcon: LucideIcons.user,
                controller: _fullNameController,
                errorText: _fullNameError,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email',
                hint: 'you@business.com',
                leadingIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                errorText: _emailError,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Mobile Number (optional)',
                hint: '070 123 45 67',
                leadingIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                controller: _mobileController,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                hint: 'Create a password',
                leadingIcon: LucideIcons.lock,
                obscureText: true,
                controller: _passwordController,
                errorText: _passwordError,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                leadingIcon: LucideIcons.lock,
                obscureText: true,
                controller: _confirmPasswordController,
                errorText: _confirmPasswordError,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Create Account',
                onPressed: widget.isLoading ? null : _handleCreateAccount,
                isLoading: widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: 'Continue with Google',
                icon: LucideIcons.globe,
                onPressed: widget.isLoading ? null : widget.onGoogleSignIn,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: widget.isLoading ? null : widget.onLogin,
                    child: Text(
                      'Login',
                      style: AppTypography.bodyMD.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
