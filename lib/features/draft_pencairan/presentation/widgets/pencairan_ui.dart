import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The look of Catat Pencairan, shared by the draft screens so they read as
/// one flow: a grey rounded back button, bold title, spaced section labels,
/// white 12px inputs, pill chips and soft cards.

/// Title row with the app's grey rounded back button. Going back uses
/// `maybePop`, so a screen guarding unsaved edits with a `PopScope` is asked.
class PencairanHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const PencairanHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          InkWell(
            key: const Key('kembali'),
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey[800], size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

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
          color: _field ? Colors.grey[700] : Colors.black87,
          fontSize: _field ? 11 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      );
}

InputDecoration pencairanInputDecoration({String? hintText}) => InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyle.small.copyWith(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.greenDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

/// Text style of what is typed into a [pencairanInputDecoration] field.
TextStyle get pencairanInputStyle =>
    AppTextStyle.small.copyWith(color: Colors.black87);

/// A pill: solid green when selected, light grey otherwise.
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
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenDark : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyle.small.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.extraSmall.copyWith(
                    color: selected ? AppColors.greenDark : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
          borderRadius: BorderRadius.circular(16),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!, width: 2),
          boxShadow: _shadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
          fontWeight: FontWeight.bold,
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
    final muted =
        AppTextStyle.small.copyWith(color: Colors.grey[700], fontSize: 12);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: muted),
          TextSpan(
            text: nama,
            style: muted.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
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

  static const _merah = Color(0xFFC62828);
  static const _merahMuda = Color(0xFFFDECEC);
  static const _hijauMuda = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: Icon(Icons.more_vert, color: Colors.grey[800]),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    borderRadius: BorderRadius.circular(10),
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
                      fontWeight: FontWeight.w600,
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
