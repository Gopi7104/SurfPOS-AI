import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// Convenience wrapper around [AppDialog] for yes/no confirmations (e.g.
/// "Cancel this sale?", "Remove product?"). Returns `true` if the user
/// confirmed, `false`/`null` otherwise — always check the return value
/// before acting, never assume confirmation from the dialog being shown.
Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      message: message,
      tone: isDestructive ? AppDialogTone.error : AppDialogTone.warning,
      primaryLabel: confirmLabel,
      onPrimary: () => Navigator.of(dialogContext).pop(true),
      secondaryLabel: cancelLabel,
      onSecondary: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return result ?? false;
}
