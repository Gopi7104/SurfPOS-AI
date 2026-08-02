import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_typography.dart';

/// A generic initials-on-a-colored-circle avatar — the app-wide building
/// block for "AvatarCard" (Dashboard's header, top-customer insights,
/// anywhere else a person/business needs a compact visual identity but has
/// no photo). Distinct from Customers' own `CustomerAvatar` (which is typed
/// to `CustomerModel`) — this one takes a plain [name] so any feature can
/// use it without a Customers dependency. Background color is picked from a
/// small, fixed brand-derived palette by hashing [name], purely so
/// consecutive avatars in a list read as visually distinct — never an
/// arbitrary invented hue (see `AppColors`'s own "official colors" rule).
class AppAvatar extends StatelessWidget {
  const AppAvatar(
      {required this.name, this.size = 44, this.background, super.key});

  final String name;
  final double size;

  /// Overrides the hash-derived background — e.g. white-on-gradient-header
  /// contexts that need a fixed, theme-consistent tint instead.
  final Color? background;

  static const _palette = [
    AppColors.primary,
    AppColors.primaryLight,
    AppColors.primaryDark,
    AppColors.success,
    AppColors.warning,
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return letters.isEmpty ? '?' : letters;
  }

  Color get _background =>
      background ?? _palette[name.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.bodyMD.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
