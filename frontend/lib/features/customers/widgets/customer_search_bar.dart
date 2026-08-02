import 'package:flutter/material.dart';

import '../../../core/widgets/text_fields/app_search_field.dart';

/// Customer List's search field — thin wrapper over the shared
/// [AppSearchField] with this screen's own hint text baked in, mirroring
/// how Reports/Inventory each supply their own hint to the same shared
/// field rather than a new implementation.
class CustomerSearchBar extends StatelessWidget {
  const CustomerSearchBar({this.controller, this.onChanged, super.key});

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      hint: 'Search by name, phone, email, or customer ID',
      controller: controller,
      onChanged: onChanged,
    );
  }
}
