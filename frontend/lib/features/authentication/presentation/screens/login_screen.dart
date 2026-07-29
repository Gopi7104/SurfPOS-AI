import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/widgets/branding/surfboard_logo.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/text_fields/app_text_field.dart';

/// Screen 2 — Login.
///
/// Presentation-only: captures an identifier (email or phone) + password
/// and reports them via [onSignIn]. No auth/business logic lives here —
/// that arrives with Firebase Authentication integration (see
/// docs/05_FEATURES.md § 2, docs/07_CODING_RULES.md § 14). [isLoading] is
/// controlled by the caller once real submission exists; local validation
/// below is feedback-only (required-field checks), never the source of
/// truth. See BRANDING in the design brief — the Surfboard mark is
/// required on this screen, shown here via [SurfboardLogo.badge] since the
/// background is a light surface (see docs/16_AI... no — see
/// core/widgets/branding/surfboard_logo.dart for the white-icon rationale).
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.onSignIn,
    this.onForgotPassword,
    this.onCreateAccount,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final void Function(String identifier, String password)? onSignIn;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _identifierError =
          identifier.isEmpty ? 'Enter your email or phone number' : null;
      // Deliberately distinct from the field's hint text ("Enter your
      // password") so a `find.text('Enter your password')` in tests (or a
      // screen reader) doesn't ambiguously match two widgets at once.
      _passwordError = password.isEmpty ? 'Password is required' : null;
    });

    if (_identifierError != null || _passwordError != null) {
      return;
    }

    widget.onSignIn?.call(identifier, password);
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
                'Welcome back',
                textAlign: TextAlign.center,
                style: AppTypography.headingLG,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to manage your store',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (widget.errorMessage != null) ...[
                _ErrorBanner(message: widget.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                label: 'Email or phone number',
                hint: 'you@business.com',
                leadingIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                controller: _identifierController,
                errorText: _identifierError,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                leadingIcon: LucideIcons.lock,
                obscureText: true,
                controller: _passwordController,
                errorText: _passwordError,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.isLoading ? null : widget.onForgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'Sign In',
                onPressed: widget.isLoading ? null : _handleSignIn,
                isLoading: widget.isLoading,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.bodyMD
                        .copyWith(color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: widget.isLoading ? null : widget.onCreateAccount,
                    child: Text(
                      'Create one',
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySM.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
