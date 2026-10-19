import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/report_file_action.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';

/// Pesan sukses setelah laporan tersimpan di [folder].
String laporanTersimpanDi(String folder) =>
    'Laporan berhasil disimpan ke folder $folder';

/// Menyiapkan laporan XLSX untuk periode dan filter yang sedang dipilih, lalu
/// menyimpannya atau membagikannya.
Future<void> exportAktivitasReport(BuildContext context) async {
  final cubit = context.read<RiwayatAktivitasCubit>();
  final loading = AppNotification.showLoading(
    context,
    title: 'Informasi',
    message: 'Menyiapkan laporan XLSX...',
  );
  final (:export, :error) = await cubit.exportTransaksi();
  await loading.dismiss();
  if (!context.mounted) return;
  if (error != null) {
    AppNotification.showError(context, title: 'Gagal', message: error);
    return;
  }
  await saveReportFile(
    context,
    filename: export!.filename,
    bytes: export.bytes,
    successMessage: laporanTersimpanDi,
    shareText: 'Laporan Transaksi PILAH',
  );
}
