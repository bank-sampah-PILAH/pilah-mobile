import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Which of the app's button looks to use.
enum AppButtonVariant {
  /// The main action of a screen or sheet: green, filled.
  primary,

  /// A second action of equal weight, such as "Tambah Nasabah": green outline.
  outlined,

  /// The way out of a flow, such as "Batal" or "Kembali": grey outline.
  neutral,

  /// An action that cannot be undone, such as logging out or rejecting: red,
  /// filled.
  destructive,

  /// The lighter form of [destructive], for an action next to a primary one,
  /// such as "Tolak" beside "Setujui": red outline.
  destructiveOutlined,
}

/// The one button of the app. Use it instead of styling an `ElevatedButton`
/// or `OutlinedButton` per screen.
///
/// It is 48 high, rounded 12 and, by default, as wide as the space it is
/// given. [isLoading] swaps the label for a spinner and ignores taps, and a
/// null [onPressed] greys it out. The look of the green variants comes from
/// `AppTheme`, so a plain Material button elsewhere looks the same.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.leading,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Replaces [icon] with any widget, such as a brand logo.
  final Widget? leading;
  final bool isLoading;

  /// Whether the button fills the width it is given. When false it is only as
  /// wide as its label.
  final bool expand;

  static const double height = 48;

  Color get _spinnerColor => switch (variant) {
        AppButtonVariant.outlined => AppColors.greenDark,
        AppButtonVariant.neutral => AppColors.inkSoft,
        AppButtonVariant.destructiveOutlined => AppColors.danger,
        _ => Colors.white,
      };

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final content = isLoading ? _spinner() : _content();
    // The spinner has no text, so the label stays available to screen readers.
    final child = isLoading
        ? Semantics(label: label, excludeSemantics: true, child: content)
        : content;
    final size = Size(expand ? double.infinity : 0, height);

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(minimumSize: size),
          child: child,
        ),
      AppButtonVariant.destructive => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: size,
            backgroundColor: AppColors.danger,
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(minimumSize: size),
          child: child,
        ),
      AppButtonVariant.neutral => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.inkSoft,
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          child: child,
        ),
      AppButtonVariant.destructiveOutlined => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          child: child,
        ),
    };
  }

  Widget _spinner() => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: _spinnerColor,
        ),
      );

  Widget _content() {
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final lead = leading ?? (icon == null ? null : Icon(icon, size: 20));
    if (lead == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        lead,
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }
}
