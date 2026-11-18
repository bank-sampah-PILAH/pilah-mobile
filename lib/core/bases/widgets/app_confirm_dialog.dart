import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';

/// Asks the user to confirm an action and answers `true` only when they tap the
/// confirm button. Cancelling, or dismissing by tapping outside or going back,
/// answers `false`.
///
/// The one confirmation dialog of the app: use it instead of building an
/// `AlertDialog` per screen. [destructive] paints the confirm button red, for
/// actions such as logging out or deleting.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return confirmed ?? false;
}
