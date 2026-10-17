import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

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

  /// A step that goes ahead despite a warning, such as confirming something
  /// that cannot be fully checked: amber, filled.
  warning,

  /// The lighter form of [warning], for an action that fixes a mismatch: amber
  /// outline.
  warningOutlined,

  /// A soft green fill with a green label, for an action that sits next to a
  /// primary one without competing with it, such as "Tandai Selesai".
  tonal,

  /// A bare green label with no padding, for a link inside a line of content,
  /// such as "Detail Bank Sampah". It is only as wide as its label.
  text,
}

/// How tall an [AppButton] is.
enum AppButtonSize {
  /// 48 high: the button of a form, a dialog or the foot of a sheet.
  regular,

  /// 40 high: an action inside a card or a list row.
  compact,
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
    this.size = AppButtonSize.regular,
    this.icon,
    this.leading,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;

  /// Replaces [icon] with any widget, such as a brand logo.
  final Widget? leading;

  /// An icon after the label, such as the arrow of a "next" action.
  final IconData? trailingIcon;
  final bool isLoading;

  /// Whether the button fills the width it is given. When false it is only as
  /// wide as its label.
  final bool expand;

  static const double height = 48;
  static const double compactHeight = 40;

  Color get _spinnerColor => switch (variant) {
        AppButtonVariant.outlined ||
        AppButtonVariant.tonal ||
        AppButtonVariant.text =>
          AppColors.greenDark,
        AppButtonVariant.neutral => AppColors.inkSoft,
        AppButtonVariant.destructiveOutlined => AppColors.danger,
        AppButtonVariant.warningOutlined => AppColors.warning,
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
    final compact = size == AppButtonSize.compact;
    final minimum = Size(
      expand ? double.infinity : 0,
      compact ? compactHeight : height,
    );
    // A button that fills its width needs no side padding to look roomy, and
    // two of them side by side must still fit a label like "Ya, Nonaktifkan".
    // A compact button sits inside a card or a row: it must not grow back to
    // the 48 of the default tap target.
    final tapTarget = compact
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded;
    final textStyle = compact
        ? AppTextStyle.small.copyWith(fontWeight: FontWeight.w600)
        : null;
    final padding = EdgeInsets.symmetric(
      horizontal: expand ? 12 : (compact ? 16 : 24),
      vertical: compact ? 8 : 12,
    );

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
          ),
          child: child,
        ),
      AppButtonVariant.destructive => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
            backgroundColor: AppColors.danger,
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
          ),
          child: child,
        ),
      AppButtonVariant.neutral => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.inkSoft,
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          child: child,
        ),
      AppButtonVariant.destructiveOutlined => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          child: child,
        ),
      AppButtonVariant.warning => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
            backgroundColor: AppColors.warning,
          ),
          child: child,
        ),
      AppButtonVariant.warningOutlined => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
            foregroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning, width: 1.5),
          ),
          child: child,
        ),
      AppButtonVariant.tonal => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: minimum,
            padding: padding,
            tapTargetSize: tapTarget,
            textStyle: textStyle,
            backgroundColor: AppColors.greenLight,
            foregroundColor: AppColors.greenDark,
          ),
          child: child,
        ),
      // A link inside a line of content hugs its label and has no padding, so
      // it lines up with the text around it.
      AppButtonVariant.text => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerLeft,
            foregroundColor: AppColors.greenDark,
            textStyle: AppTextStyle.small.copyWith(fontWeight: FontWeight.w600),
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
    // A label that is too wide for its button, such as "Ya, Nonaktifkan" in a
    // half-width button on a 360 dp phone, shrinks to fit rather than being cut.
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    );
    final iconSize = size == AppButtonSize.compact ? 16.0 : 20.0;
    final iconData = icon;
    final lead =
        leading ?? (iconData == null ? null : Icon(iconData, size: iconSize));
    if (lead == null && trailingIcon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lead != null) ...[lead, const SizedBox(width: 8)],
        Flexible(child: text),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );
  }
}
