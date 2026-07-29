import 'package:flutter/material.dart';

/// Data for a single [AppBottomNavBar] destination.
class AppNavItem {
  const AppNavItem(
      {required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
