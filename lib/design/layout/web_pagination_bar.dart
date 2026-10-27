import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';

class WebPaginationBar extends StatelessWidget {
  const WebPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.itemLabel,
    required this.onPageChanged,
  }) : assert(pageSize > 0);

  final int currentPage;
  final int totalItems;
  final int pageSize;
  final String itemLabel;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pageCount =
        totalItems <= 0 ? 1 : (totalItems + pageSize - 1) ~/ pageSize;
    final page = currentPage.clamp(1, pageCount).toInt();
    final start = totalItems == 0 ? 0 : (page - 1) * pageSize + 1;
    final end = math.min(page * pageSize, totalItems);
    final format = NumberFormat.decimalPattern('id');
    final range =
        'Menampilkan ${format.format(start)}–${format.format(end)} dari ${format.format(totalItems)} $itemLabel';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final controls = _controls(page, pageCount, compact: compact);
        if (compact) {
          return Column(
            children: [
              Text(range,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
              if (pageCount > 1) ...[
                const SizedBox(height: AppSpacing.xs),
                controls,
              ],
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(range,
                style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
            if (pageCount > 1) controls,
          ],
        );
      },
    );
  }

  Widget _controls(int page, int pageCount, {required bool compact}) {
    final pages = _visiblePages(page, pageCount, compact: compact);
    final buttons = <Widget>[
      IconButton(
        tooltip: 'Halaman sebelumnya',
        onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
        icon: const Icon(Icons.chevron_left),
      ),
    ];
    var previous = 0;
    for (final number in pages) {
      if (number - previous > 1) {
        buttons.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('…', style: AppTextStyle.small),
        ));
      }
      buttons.add(_pageButton(number, selected: number == page));
      previous = number;
    }
    buttons.add(IconButton(
      tooltip: 'Halaman berikutnya',
      onPressed: page < pageCount ? () => onPageChanged(page + 1) : null,
      icon: const Icon(Icons.chevron_right),
    ));
    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  List<int> _visiblePages(int page, int pageCount, {required bool compact}) {
    if (pageCount <= 5) return [for (var i = 1; i <= pageCount; i++) i];
    final pages = <int>{1, pageCount, page};
    if (compact) {
      if (page == 1) pages.add(2);
      if (page == pageCount) pages.add(pageCount - 1);
    } else {
      if (page > 1) pages.add(page - 1);
      if (page < pageCount) pages.add(page + 1);
    }
    return pages.toList()..sort();
  }

  Widget _pageButton(int page, {required bool selected}) => AppTapTarget(
        label: 'Halaman $page',
        selected: selected,
        onTap: selected ? null : () => onPageChanged(page),
        minSize: 48,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.greenDark : Colors.white,
            border: Border.all(
                color: selected ? AppColors.greenDark : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            NumberFormat.decimalPattern('id').format(page),
            style: AppTextStyle.small.copyWith(
              color: selected ? Colors.white : AppColors.inkSoft,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}
