import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import 'layout_breakpoint.dart';

/// Kepala halaman tab di shell web: judul, subjudul opsional, pencarian, dan
/// aksi, dengan jarak yang sama di setiap halaman.
///
/// Pada layar lebar semuanya satu baris: judul di kiri, pencarian selebar
/// [searchWidth] di kanan judul, lalu [actions]. Di bawah expanded pencarian
/// turun di bawah judul dan selebar baris.
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

  final String title;
  final Widget? subtitle;

  /// Biasanya [CustomSearchField]. Lebarnya diatur header ini.
  final Widget? search;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
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
    final inline = context.layoutBreakpoint == LayoutBreakpoint.expanded;
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
