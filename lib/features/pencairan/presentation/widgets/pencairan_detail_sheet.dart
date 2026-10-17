import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';

import '../../domain/model/pencairan.dart';
import '../pages/edit_pencairan_page.dart';
import '../pages/revisi_pencairan_page.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';

String _time(DateTime? tanggal) {
  if (tanggal == null) return '-';
  final h = tanggal.hour.toString().padLeft(2, '0');
  final m = tanggal.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _statusLabel(String status) =>
    status.isEmpty ? '-' : status[0].toUpperCase() + status.substring(1);

/// Opens the pencairan detail sheet, with the Pengurus-only edit and
/// riwayat-perubahan entry points (PIL-230). Shared by every screen that
/// lists pencairan rows — previously duplicated only inside the standalone
/// Riwayat Pencairan page, now also used by the unified Riwayat Aktivitas
/// feed (PIL-282). Calls [onChanged] after a successful edit so the caller
/// can refresh its own list.
Future<void> showPencairanDetailSheet(
  BuildContext context,
  Pencairan item, {
  required VoidCallback onChanged,
}) {
  Future<void> edit() async {
    final saved = await GoRouter.of(context)
        .push<bool>(EditPencairanPage.route, extra: item);
    if (saved == true) onChanged();
  }

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _DetailPencairanSheet(
      item: item,
      onEdit: () {
        Navigator.of(sheetContext).pop();
        edit();
      },
      onRiwayatPerubahan: () {
        Navigator.of(sheetContext).pop();
        GoRouter.of(context)
            .push<void>(RevisiPencairanPage.route, extra: item.id);
      },
    ),
  );
}

Future<void> showNasabahPencairanDetailSheet(
  BuildContext context,
  Pencairan item,
) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailPencairanSheet(item: item),
    );

/// Marks a pencairan a pengurus has edited (PIL-230).
class DiperbaruiLabel extends StatelessWidget {
  const DiperbaruiLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Diperbarui',
      style: NasabahStyle.text(12, color: NasabahStyle.emerald)
          .copyWith(fontStyle: FontStyle.italic),
    );
  }
}

class _DetailPencairanSheet extends StatelessWidget {
  final Pencairan item;
  final VoidCallback? onEdit;
  final VoidCallback? onRiwayatPerubahan;

  const _DetailPencairanSheet({
    required this.item,
    this.onEdit,
    this.onRiwayatPerubahan,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal = item.tanggal;
    return AppSheetContainer(
      color: NasabahStyle.background,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NasabahStyle.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detail Pencairan',
                  style: NasabahStyle.text(20, weight: FontWeight.w600),
                ),
              ),
              if (item.diperbarui) const DiperbaruiLabel(),
            ],
          ),
          const SizedBox(height: 16),
          AppDetailRow(label: 'Nasabah', value: item.nasabahNama),
          AppDetailRow(
              label: 'Nominal',
              value: 'Rp ${CurrencyFormatter.formatNumber(item.nominal)}'),
          AppDetailRow(
              label: 'Potongan',
              value: 'Rp ${CurrencyFormatter.formatNumber(item.potongan)}'),
          AppDetailRow(
              label: 'Dibayar',
              value: 'Rp ${CurrencyFormatter.formatNumber(item.dibayar)}'),
          AppDetailRow(label: 'Metode', value: item.metode.label),
          AppDetailRow(
              label: 'Tanggal',
              value: tanggal == null
                  ? '-'
                  : '${formatTanggalId(tanggal)}, ${_time(tanggal)}'),
          AppDetailRow(label: 'Status', value: _statusLabel(item.status)),
          AppDetailRow(
              label: 'Keterangan',
              value: item.keterangan.isEmpty ? '-' : item.keterangan),
          AppDetailRow(
              label: 'Saldo sebelum',
              value: 'Rp ${CurrencyFormatter.formatNumber(item.saldoSebelum)}'),
          AppDetailRow(
              label: 'Saldo sesudah',
              value: 'Rp ${CurrencyFormatter.formatNumber(item.saldoSesudah)}'),
          AppDetailRow(
              label: 'Dicatat oleh',
              value: item.dicatatOlehNama.isEmpty ? '-' : item.dicatatOlehNama),
          const SizedBox(height: 16),
          if (onEdit != null)
            OutlinedButton.icon(
              key: const Key('edit-pencairan'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Pencairan'),
            ),
          if (item.diperbarui && onRiwayatPerubahan != null)
            TextButton.icon(
              key: const Key('riwayat-perubahan-pencairan'),
              onPressed: onRiwayatPerubahan,
              icon: const Icon(Icons.history),
              label: const Text('Riwayat Perubahan'),
            ),
        ],
      ),
    );
  }
}
