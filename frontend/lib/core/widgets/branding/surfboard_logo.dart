import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';

/// The official Surfboard Payments mark
/// (assets/logos/surfboard-payments-white-icon.svg).
///
/// **Important:** the source asset is a *white* icon — it is only visible
/// against a dark/colored background. [SurfboardLogo.badge] (the default)
/// wraps it in a Blueberry rounded container so it stays legible on the
/// white surfaces used in Login, Settings, and About. Use
/// [SurfboardLogo.bare] only when the immediate parent is already a dark
/// or gradient surface (e.g. the Splash screen background).
///
/// Never stretch the mark — [size] always drives a square box and the SVG
/// is laid out with `BoxFit.contain`.
class SurfboardLogo extends StatelessWidget {
  const SurfboardLogo.badge({this.size = 64, super.key}) : _bare = false;

  const SurfboardLogo.bare({this.size = 64, super.key}) : _bare = true;

  final double size;
  final bool _bare;

  static const _asset = 'assets/logos/surfboard-payments-white-icon.svg';

  @override
  Widget build(BuildContext context) {
    final mark = Padding(
      padding: EdgeInsets.all(size * 0.22),
      child: SvgPicture.asset(
        _asset,
        fit: BoxFit.contain,
        semanticsLabel: 'Surfboard Payments',
      ),
    );

    if (_bare) {
      return SizedBox(height: size, width: size, child: mark);
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: mark,
    );
  }
}
