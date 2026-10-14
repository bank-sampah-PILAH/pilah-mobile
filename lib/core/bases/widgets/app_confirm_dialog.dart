import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

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
    builder: (dialogContext) => AlertDialog(
      title: Text(
        title,
        style: AppTextStyle.title1.copyWith(color: AppColors.black),
      ),
      content: Text(message, style: AppTextStyle.small),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            cancelLabel,
            style: AppTextStyle.small.copyWith(
              color: AppColors.grey100,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Colors.red)
              : null,
          child: Text(
            confirmLabel,
            style: AppTextStyle.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
