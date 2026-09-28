import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import '../../domain/model/pencairan.dart';
import '../pages/edit_pencairan_page.dart';
import '../pages/revisi_pencairan_page.dart';

const _emeraldPrimary = Color(0xFF006D44);

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
    isScrollControlled: true,
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
      isScrollControlled: true,
      builder: (_) => _DetailPencairanSheet(item: item),
    );

/// Marks a pencairan a pengurus has edited (PIL-230).
class DiperbaruiLabel extends StatelessWidget {
  const DiperbaruiLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Diperbarui',
      style: AppTextStyle.small.copyWith(
        color: _emeraldPrimary,
        fontStyle: FontStyle.italic,
      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Detail Pencairan', style: AppTextStyle.title1),
              ),
              if (item.diperbarui) const DiperbaruiLabel(),
            ],
          ),
          const SizedBox(height: 16),
          _row('Nasabah', item.nasabahNama),
          _row('Nominal', 'Rp ${formatRupiahId(item.nominal)}'),
          _row('Metode', item.metode.label),
          _row(
            'Tanggal',
            tanggal == null
                ? '-'
                : '${formatTanggalId(tanggal)}, ${_time(tanggal)}',
          ),
          _row('Status', _statusLabel(item.status)),
          _row('Keterangan', item.keterangan.isEmpty ? '-' : item.keterangan),
          _row('Saldo sebelum', 'Rp ${formatRupiahId(item.saldoSebelum)}'),
          _row('Saldo sesudah', 'Rp ${formatRupiahId(item.saldoSesudah)}'),
          _row(
            'Dicatat oleh',
            item.dicatatOlehNama.isEmpty ? '-' : item.dicatatOlehNama,
          ),
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

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyle.small),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyle.title1,
              ),
            ),
          ],
        ),
      );
}
