import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../buttons/app_icon_button.dart';

/// The standard solid-Blueberry app bar for secondary/detail screens
/// (Product Details, Add Product, Notifications, Help & Support). Screens
/// that need the large hero look instead use [AppGradientHeader]. See
/// docs/06_UI_UX_GUIDE.md § 8.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    this.onBack,
    this.actions,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 4,
      leading: onBack == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: AppIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                filled: false,
                onTap: onBack,
              ),
            ),
      title: subtitle == null
          ? Text(title)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
