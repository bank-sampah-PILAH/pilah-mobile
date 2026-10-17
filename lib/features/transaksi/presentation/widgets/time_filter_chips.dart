import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/report_file_action.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/filter_tanggal_bottom_sheet.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';

/// Shared period controls and filtered operational XLSX export.
class TimeFilterChips extends StatelessWidget {
  const TimeFilterChips({super.key});

  static const Map<String, String> _chips = {
    'Hari Ini': 'hari_ini',
    'Minggu Ini': 'minggu_ini',
    'Bulan Ini': 'bulan_ini',
    'Bulan Lalu': 'bulan_lalu',
    '1 Bulan': '1_bulan',
    '3 Bulan': '3_bulan',
    '6 Bulan': '6_bulan',
    '12 Bulan': '12_bulan',
    'Semua Waktu': 'semua',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiwayatAktivitasCubit, RiwayatAktivitasState>(
      buildWhen: (previous, current) =>
          previous.periode != current.periode ||
          previous.dariTanggal != current.dariTanggal ||
          previous.sampaiTanggal != current.sampaiTanggal,
      builder: (context, state) {
        final periods = [
          for (final entry in _chips.entries)
            AppChip(
              label: entry.key,
              selected: state.periode == entry.value,
              onTap: () =>
                  context.read<RiwayatAktivitasCubit>().setPeriode(entry.value),
            ),
        ];
        final calendar = OutlinedButton.icon(
          onPressed: () => _openRange(context),
          style: state.isCustomPeriode
              ? OutlinedButton.styleFrom(
                  backgroundColor: AppColors.greenDark,
                  foregroundColor: Colors.white,
                )
              : null,
          icon: Icon(Icons.calendar_today_outlined,
              color: state.isCustomPeriode ? Colors.white : null, size: 20),
          label: const Text('Rentang Tanggal'),
        );
        final export = FilledButton.icon(
          onPressed: () => _onExport(context),
          icon: const Icon(Icons.download_rounded, size: 20),
          label: const Text('XLSX Laporan'),
        );
        return LayoutBuilder(builder: (context, constraints) {
          if (LayoutBreakpoint.fromWidth(constraints.maxWidth) !=
              LayoutBreakpoint.compact) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [...periods, calendar, export],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final period in periods)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: period,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [calendar, export]),
            ],
          );
        });
      },
    );
  }

  void _openRange(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<RiwayatAktivitasCubit>(),
        child: const FilterTanggalBottomSheet(),
      ),
    );
  }

  Future<void> _onExport(BuildContext context) async {
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
      successMessage: (folder) => 'Laporan berhasil disimpan ke folder $folder',
      shareText: 'Laporan Transaksi PILAH',
    );
  }
}
