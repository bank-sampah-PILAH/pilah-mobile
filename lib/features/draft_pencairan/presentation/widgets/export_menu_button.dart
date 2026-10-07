import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import '../../domain/model/draft_pencairan.dart';

/// The labelled "Ekspor" pill in the header, opening a small white card with
/// one row per file type. A bare three-dot icon was not read as export.
class ExportMenuButton extends StatelessWidget {
  final bool enabled;
  final ValueChanged<ExportBerkas> onSelected;

  const ExportMenuButton({
    super.key,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.grey[800] : Colors.grey[400];
    return PopupMenuButton<ExportBerkas>(
      key: const Key('menu-ekspor'),
      enabled: enabled,
      tooltip: 'Ekspor',
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black38,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        _ExportItem(
          key: const Key('ekspor-pdf'),
          berkas: ExportBerkas.pdf,
          label: 'PDF',
          icon: Icons.picture_as_pdf_outlined,
          tint: const Color(0xFFFDECEC),
          iconColor: const Color(0xFFC62828),
        ),
        _ExportItem(
          key: const Key('ekspor-xlsx'),
          berkas: ExportBerkas.xlsx,
          label: 'Excel',
          icon: Icons.table_chart_outlined,
          tint: const Color(0xFFE8F5E9),
          iconColor: AppColors.greenDark,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              'Ekspor',
              style: AppTextStyle.small
                  .copyWith(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportItem extends PopupMenuItem<ExportBerkas> {
  _ExportItem({
    super.key,
    required ExportBerkas berkas,
    required String label,
    required IconData icon,
    required Color tint,
    required Color iconColor,
  }) : super(
          value: berkas,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style:
                      AppTextStyle.small.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );
}
