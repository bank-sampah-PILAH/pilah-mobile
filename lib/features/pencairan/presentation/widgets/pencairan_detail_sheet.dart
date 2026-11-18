import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'pencairan_detail_flow.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';

import '../../domain/model/pencairan.dart';
import '../pages/edit_pencairan_page.dart';
import '../pages/revisi_pencairan_page.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

String _time(DateTime? tanggal) {
  if (tanggal == null) return '-';
  final h = tanggal.hour.toString().padLeft(2, '0');
  final m = tanggal.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _statusLabel(String status) =>
    status.isEmpty ? '-' : status[0].toUpperCase() + status.substring(1);

/// Opens the pencairan detail, with the Pengurus-only edit and
/// riwayat-perubahan entry points (PIL-230). Shared by every screen that
/// lists pencairan rows — previously duplicated only inside the standalone
/// Riwayat Pencairan page, now also used by the unified Riwayat Aktivitas
/// feed (PIL-282). Calls [onChanged] after a successful edit so the caller
/// can refresh its own list. A bottom sheet on a phone, a dialog on a wide
/// window.
Future<void> showPencairanDetailSheet(
  BuildContext context,
  Pencairan item, {
  required VoidCallback onChanged,
}) {
  // On a wide window detail, edit and history are one dialog with back
  // navigation; on a phone the edit form and the history are pages.
  if (context.layoutBreakpoint != LayoutBreakpoint.compact) {
    return showAdaptiveSurface<void>(
      context,
      builder: (_) => PencairanDetailFlow(item: item, onChanged: onChanged),
    );
  }
  final router = GoRouter.of(context);

  Future<void> edit() async {
    final saved = await router.push<bool>(EditPencairanPage.route, extra: item);
    if (saved == true) onChanged();
  }

  return showAdaptiveSurface<void>(
    context,
    builder: (sheetContext) => PencairanDetailSheet(
      item: item,
      onEdit: () {
        Navigator.of(sheetContext).pop();
        edit();
      },
      onRiwayatPerubahan: () {
        Navigator.of(sheetContext).pop();
        router.push<void>(RevisiPencairanPage.route, extra: item.id);
      },
    ),
  );
}

Future<void> showNasabahPencairanDetailSheet(
  BuildContext context,
  Pencairan item,
) =>
    showAdaptiveSurface<void>(
      context,
      builder: (_) => PencairanDetailSheet(item: item),
    );

String _rupiah(int value) => 'Rp ${CurrencyFormatter.formatNumber(value)}';

/// Isi detail pencairan. Di bottom sheet atau dialog ia membawa wadah, pegangan
/// tarik, dan judulnya sendiri; [embedded] melepas semuanya untuk panel samping
/// yang sudah punya header.
class PencairanDetailSheet extends StatelessWidget {
  final Pencairan item;
  final VoidCallback? onEdit;
  final VoidCallback? onRiwayatPerubahan;
  final bool embedded;

  const PencairanDetailSheet({
    super.key,
    required this.item,
    this.onEdit,
    this.onRiwayatPerubahan,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal = item.tanggal;
    final palette = avatarPaletteFor(item.nasabahNama);
    final lihatRiwayat = item.diperbarui && onRiwayatPerubahan != null;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded) ...[
          // A dialog cannot be dragged, so it has no handle there.
          if (!DialogSurface.of(context)) ...[
            const AppSheetHandle(),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text('Detail Pencairan',
              style: AppTextStyle.headline3.copyWith(color: AppColors.grey100)),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: palette.$1,
              child: Text(
                initialsOf(item.nasabahNama),
                style: AppTextStyle.small.copyWith(
                  color: palette.$2,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nasabahNama,
                      style:
                          AppTextStyle.title1.copyWith(color: AppColors.black)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      CustomStatusBadge(statusText: _statusLabel(item.status)),
                      if (item.diperbarui)
                        const CustomStatusBadge(
                          statusText: 'Diperbarui',
                          backgroundColor: AppColors.warningLight,
                          textColor: AppColors.warning,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _Card(
          children: [
            Text('Nominal',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
            const SizedBox(height: 2),
            Text(
              _rupiah(item.nominal),
              style: AppTextStyle.headline1.copyWith(
                color: AppColors.danger,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDetailRow(label: 'Potongan', value: _rupiah(item.potongan)),
            AppDetailRow(label: 'Dibayar', value: _rupiah(item.dibayar)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Card(
          children: [
            AppDetailRow(label: 'Metode', value: item.metode.label),
            AppDetailRow(
                label: 'Tanggal',
                value: tanggal == null
                    ? '-'
                    : '${formatTanggalId(tanggal)}, ${_time(tanggal)}'),
            AppDetailRow(
                label: 'Keterangan',
                value: item.keterangan.isEmpty ? '-' : item.keterangan),
            AppDetailRow(
                label: 'Dicatat oleh',
                value:
                    item.dicatatOlehNama.isEmpty ? '-' : item.dicatatOlehNama),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SaldoBlock(sebelum: item.saldoSebelum, sesudah: item.saldoSesudah),
        if (onEdit != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (lihatRiwayat) ...[
                Expanded(
                  child: AppButton(
                    key: const Key('riwayat-perubahan-pencairan'),
                    label: 'Riwayat Perubahan',
                    variant: AppButtonVariant.outlined,
                    icon: Icons.history,
                    onPressed: onRiwayatPerubahan,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: AppButton(
                  key: const Key('edit-pencairan'),
                  label: 'Edit Pencairan',
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                ),
              ),
            ],
          ),
        ],
      ],
    );
    return embedded ? content : AppSheetContainer(child: content);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardOffWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

/// Saldo nasabah sebelum dan sesudah pencairan: satu blok hijau muda, dengan
/// panah dari yang lama ke yang baru.
class _SaldoBlock extends StatelessWidget {
  const _SaldoBlock({required this.sebelum, required this.sesudah});

  final int sebelum;
  final int sesudah;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, int value, {bool emphasis = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyle.extraSmall
                      .copyWith(color: AppColors.grey100)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _rupiah(value),
                  style: AppTextStyle.headline3.copyWith(
                    color: emphasis ? AppColors.greenDark : AppColors.black,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          cell('Saldo sebelum', sebelum),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child:
                Icon(Icons.arrow_forward, size: 18, color: AppColors.greenDark),
          ),
          cell('Saldo sesudah', sesudah, emphasis: true),
        ],
      ),
    );
  }
}
