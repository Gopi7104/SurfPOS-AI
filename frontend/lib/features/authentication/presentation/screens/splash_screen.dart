import 'package:flutter/material.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/app_typography.dart';
import '../../../../core/widgets/branding/surfboard_logo.dart';

/// Screen 1 — Splash.
///
/// Brand entrance: gradient background, the Surfboard Payments mark, and
/// the app name, with a fade + scale entrance animation. See
/// docs/05_FEATURES.md and the BRANDING section of the design brief
/// (splash is one of the five contexts the official logo must appear in).
///
/// [onReady] fires once the entrance animation + a short hold have
/// finished — wire it to session-check/routing logic once
/// Login/Onboarding/Dashboard exist (deliberately left unwired for now;
/// see .claude/memory.md — screens are being built one at a time).
class SplashScreen extends StatefulWidget {
  const SplashScreen({this.onReady, super.key});

  final VoidCallback? onReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    if (widget.onReady != null) {
      Future.delayed(const Duration(milliseconds: 2200), widget.onReady);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SurfboardLogo.bare(size: 96),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'SurfPOS AI',
                            style: AppTypography.displayXL
                                .copyWith(color: AppColors.white),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Powered by Surfboard Payments',
                            style: AppTypography.bodyMD.copyWith(
                              color: AppColors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
