import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

/// The question dialog of the app: a title, a message (or any [content], such
/// as a text field), a quiet cancel and a confirm button.
///
/// It is an `AlertDialog`, so `AppTheme` gives it the white surface and the 16
/// radius. Use it, or `showAppConfirmDialog` for a plain yes-or-no, instead of
/// building an `AlertDialog` per screen. [destructive] paints the confirm
/// button red, for an action that cannot be undone.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.cancelLabel = 'Batal',
    this.destructive = false,
    this.isLoading = false,
  }) : assert(message == null || content == null,
            'give a message or a content, not both');

  final String title;
  final String? message;

  /// Replaces [message], for a dialog that asks for input.
  final Widget? content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool destructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: AppTextStyle.title1),
      content: content ??
          (message == null ? null : Text(message!, style: AppTextStyle.small)),
      actions: [
        TextButton(
          onPressed: isLoading ? null : onCancel,
          child: Text(
            cancelLabel,
            style: AppTextStyle.small.copyWith(
              color: AppColors.grey100,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppButton(
          label: confirmLabel,
          variant: destructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          expand: false,
          isLoading: isLoading,
          onPressed: onConfirm,
        ),
      ],
    );
  }
}

/// How an [AppIconDialog] weighs what it asks: green for going ahead, amber for
/// a warning, red for something that cannot be undone.
enum AppDialogTone {
  positive(AppColors.greenDark, AppColors.greenLight),
  warning(AppColors.warning, AppColors.warningLight),
  danger(AppColors.danger, AppColors.dangerLight);

  const AppDialogTone(this.color, this.tint);

  final Color color;
  final Color tint;
}

/// A confirmation that leads with an icon in a tinted circle, for a decision
/// about a person or an item, such as deactivating a nasabah. The title and
/// [message] are centred and the two answers sit side by side.
///
/// [message] is a list of spans so a name can be bold. [isLoading] spins the
/// confirm button and locks both answers while the action runs.
class AppIconDialog extends StatelessWidget {
  const AppIconDialog({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.cancelLabel = 'Batal',
    this.destructive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final AppDialogTone tone;
  final String title;
  final List<InlineSpan> message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool destructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: tone.tint, shape: BoxShape.circle),
              child: Icon(icon, color: tone.color, size: 32),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTextStyle.title1, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
                children: message,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.neutral,
                    onPressed: isLoading ? null : onCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: destructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    isLoading: isLoading,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
