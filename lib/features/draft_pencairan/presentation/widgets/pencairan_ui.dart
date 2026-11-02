import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// The look of Catat Pencairan, shared by the draft screens so they read as
/// one flow: a grey rounded back button, bold title, spaced section labels,
/// white 12px inputs, pill chips and soft cards.

/// Heading above a group of fields (`RINGKASAN`). [SectionLabel.field] is the
/// quieter label of a single field inside a card (`NOMINAL`).
class SectionLabel extends StatelessWidget {
  final String text;
  final bool _field;

  const SectionLabel(this.text, {super.key}) : _field = false;

  const SectionLabel.field(this.text, {super.key}) : _field = true;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyle.extraSmall.copyWith(
          color: _field ? AppColors.inkSoft : AppColors.black,
          fontSize: _field ? 11 : 12,
          fontWeight: AppFontWeight.bold,
          letterSpacing: 1.0,
        ),
      );
}

/// A pill: solid green when selected, light grey otherwise. It is an
/// [AppChip] under the hood, so it is announced to screen readers as a
/// selected or unselected button.
class PencairanChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// A small count after the label, such as how many drafts the chip holds.
  final int? count;

  const PencairanChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) => AppChip(
        label: label,
        selected: selected,
        onTap: onTap,
        icon: icon,
        count: count,
      );
}

/// White box with a 2px green outline, for a panel such as the options that
/// apply to everyone. [PencairanCard.shadow] is the softer card used for each
/// nasabah or draft: no outline, a shadow instead. Either takes a
/// [borderColor] to mark an error or a selection.
class PencairanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final bool _shadow;

  const PencairanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = AppColors.greenDark,
  }) : _shadow = false;

  const PencairanCard.shadow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  }) : _shadow = true;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!, width: 2),
          boxShadow: _shadow
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      );
}

/// Round avatar with the nasabah's initials, coloured from the same palette as
/// the nasabah list, so a person looks the same on every screen. There is no
/// photo to show yet; a photo would replace the initials here.
class PencairanAvatar extends StatelessWidget {
  final String nama;
  final double size;

  const PencairanAvatar({super.key, required this.nama, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = avatarPaletteFor(nama);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initialsOf(nama),
        style: AppTextStyle.small.copyWith(
          color: foreground,
          fontWeight: AppFontWeight.bold,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// `Dibuat oleh Nama · 8 Okt 2026, 06:59` with the name picked out in dark.
class PencairanMetaLine extends StatelessWidget {
  final String label;
  final String nama;
  final String waktu;

  const PencairanMetaLine({
    super.key,
    required this.label,
    required this.nama,
    required this.waktu,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyle.small
        .copyWith(color: AppColors.inkSoft, fontSize: AppFontSize.sm);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: muted),
          TextSpan(
            text: nama,
            style: muted.copyWith(
              color: AppColors.black,
              fontWeight: AppFontWeight.semibold,
            ),
          ),
          TextSpan(text: ' \u00b7 $waktu', style: muted),
        ],
      ),
    );
  }
}

/// One row of a [PencairanPopupMenu]: what it does, and the icon that says so.
class PencairanMenuEntry<T> {
  final Key? key;
  final T value;
  final String label;
  final IconData icon;

  /// Reads red: the action removes or discards something.
  final bool destruktif;

  const PencairanMenuEntry({
    this.key,
    required this.value,
    required this.label,
    required this.icon,
    this.destruktif = false,
  });
}

/// The three-dot menu of the pencairan screens: a white, rounded card with no
/// Material tint, each row led by an icon in a small tinted square, like the
/// export card. Replaces the default grey popup.
class PencairanPopupMenu<T> extends StatelessWidget {
  final List<PencairanMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final String tooltip;

  const PencairanPopupMenu({
    super.key,
    required this.entries,
    required this.onSelected,
    this.tooltip = 'Menu',
  });

  static const _merah = AppColors.danger;
  static const _merahMuda = AppColors.dangerLight;
  static const _hijauMuda = AppColors.greenLight;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: const Icon(Icons.more_vert, color: AppColors.inkSoft),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: AppColors.grey200,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final entry in entries)
          PopupMenuItem<T>(
            key: entry.key,
            value: entry.value,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: entry.destruktif ? _merahMuda : _hijauMuda,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    entry.icon,
                    size: 20,
                    color: entry.destruktif ? _merah : AppColors.greenDark,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    entry.label,
                    style: AppTextStyle.small.copyWith(
                      fontWeight: AppFontWeight.semibold,
                      color: entry.destruktif ? _merah : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A 52px action button with an icon, sized to sit beside another one.
///
/// The label shrinks to fit rather than overflowing, so two of these share a
/// row even on a narrow phone. While [isLoading] the icon becomes a spinner
/// (the width stays put) and taps are ignored.
class PencairanActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool isLoading;
  final VoidCallback? onPressed;

  const PencairanActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => AppButton(
        label: label,
        icon: icon,
        variant: filled ? AppButtonVariant.primary : AppButtonVariant.outlined,
        isLoading: isLoading,
        onPressed: onPressed,
      );
}
