import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_typography.dart';
import '../models/customer_model.dart';

/// A customer's avatar — initials on a colored circle (this module never
/// collects a photo). The background color is picked from a small, fixed
/// brand-derived palette by hashing the customer's id, purely so
/// consecutive rows in a list read as visually distinct — never an
/// arbitrary invented hue (see `AppColors`'s own "official colors" rule).
class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({required this.customer, this.size = 48, super.key});

  final CustomerModel customer;
  final double size;

  static const _palette = [
    AppColors.primary,
    AppColors.primaryLight,
    AppColors.primaryDark,
    AppColors.success,
    AppColors.warning,
  ];

  String get _initials {
    final first = customer.firstName.isNotEmpty ? customer.firstName[0] : '';
    final last = customer.lastName.isNotEmpty ? customer.lastName[0] : '';
    final initials = '$first$last'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  Color get _background =>
      _palette[customer.id.hashCode.abs() % _palette.length];

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
