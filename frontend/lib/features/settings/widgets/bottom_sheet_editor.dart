import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/widgets/buttons/app_primary_button.dart';
import '../../../core/widgets/text_fields/app_text_field.dart';

/// Shared chrome for every Settings bottom-sheet edit surface — grab
/// handle, title, scrollable content, optional full-width primary action.
/// Every multi-field or single-field-but-sheet edit in Settings (Receipt,
/// Barcode, Merchant Profile field edits, ...) builds on this one shell
/// instead of a bespoke `showModalBottomSheet` call per site.
class BottomSheetEditor extends StatelessWidget {
  const BottomSheetEditor({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Text(title, style: AppTypography.headingSM),
              const SizedBox(height: AppSpacing.sm),
              child,
              if (onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                    label: actionLabel ?? 'Save', onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a [BottomSheetEditor] holding a single [AppTextField] — the
/// pattern every Merchant Profile field edit (Business Name, Email,
/// Phone, ...) uses, so that flow isn't duplicated seven times.
Future<void> showTextFieldEditorSheet(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hint,
  TextInputType? keyboardType,
  required ValueChanged<String?> onSave,
}) {
  final controller = TextEditingController(text: initialValue);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BottomSheetEditor(
      title: title,
      onAction: () {
        final trimmed = controller.text.trim();
        onSave(trimmed.isEmpty ? null : trimmed);
        Navigator.of(sheetContext).pop();
      },
      child: AppTextField(
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
      ),
    ),
  );
}
