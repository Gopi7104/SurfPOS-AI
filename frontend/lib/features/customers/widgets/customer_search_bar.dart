import 'package:flutter/material.dart';

import '../../../core/widgets/text_fields/app_search_field.dart';

/// Customer List's search field — thin wrapper over the shared
/// [AppSearchField] with this screen's own hint text baked in, mirroring
/// how Reports/Inventory each supply their own hint to the same shared
/// field rather than a new implementation.
class CustomerSearchBar extends StatelessWidget {
  const CustomerSearchBar(
      {this.controller, this.focusNode, this.onChanged, super.key});

  final TextEditingController? controller;

  /// Lets the Hero's search shortcut focus this field directly — see
  /// `CustomerListPage`.
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      hint: 'Search by name, phone, email, or customer ID',
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
    );
  }
}
