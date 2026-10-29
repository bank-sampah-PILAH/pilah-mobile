import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

/// Shows [child] (a photo, a document preview) in a dialog with a cross in the
/// corner and a close button at the foot, over a black backdrop so the media
/// stands out.
Future<void> showAppMediaDialog(
  BuildContext context, {
  required Widget child,
  String closeLabel = 'Tutup',
}) =>
    showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.87),
      builder: (_) => AppMediaDialog(closeLabel: closeLabel, child: child),
    );

/// The dialog of [showAppMediaDialog]: for looking at one piece of media, as
/// opposed to `AppDialog`, which asks a question.
class AppMediaDialog extends StatelessWidget {
  const AppMediaDialog({
    super.key,
    required this.child,
    this.closeLabel = 'Tutup',
  });

  final Widget child;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon:
                    const Icon(Icons.close, color: AppColors.grey100, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(20), child: child),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: closeLabel,
                  variant: AppButtonVariant.neutral,
                  expand: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
