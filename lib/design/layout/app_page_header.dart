import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Kepala halaman tab di shell web: judul, subjudul opsional, pencarian, dan
/// aksi, dengan jarak yang sama di setiap halaman.
///
/// Bila ruangnya cukup ([inlineMinWidth]) semuanya satu baris: judul di kiri,
/// pencarian selebar [searchWidth] di kanan judul, lalu [actions]. Bila tidak,
/// pencarian turun di bawah judul dan selebar baris. Yang dihitung adalah
/// lebar yang diberikan kepadanya, bukan lebar jendela, karena halaman dengan
/// panel samping hanya menyisakan sebagian.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.search,
    this.actions = const [],
  });

  /// Lebar kolom pencarian di baris judul.
  static const double searchWidth = 360;

  /// Lebar minimum agar judul, pencarian, dan sebuah tombol muat satu baris.
  static const double inlineMinWidth = 880;

  final String title;
  final Widget? subtitle;

  /// Biasanya [CustomSearchField]. Lebarnya diatur header ini.
  final Widget? search;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            _build(constraints.maxWidth >= inlineMinWidth),
      );

  Widget _build(bool inline) {
    final titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyle.headline1.copyWith(color: AppColors.black)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: AppTextStyle.small.copyWith(color: AppColors.grey100),
            child: subtitle!,
          ),
        ],
      ],
    );
    if (inline) {
      return Row(
        children: [
          Expanded(child: titleBlock),
          if (search != null) ...[
            const SizedBox(width: AppSpacing.xl),
            SizedBox(width: searchWidth, child: search),
          ],
          for (final action in actions) ...[
            const SizedBox(width: AppSpacing.md),
            action,
          ],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: titleBlock),
          for (final action in actions) ...[
            const SizedBox(width: AppSpacing.md),
            action,
          ],
        ]),
        if (search != null) ...[
          const SizedBox(height: AppSpacing.lg),
          search!,
        ],
      ],
    );
  }
}
