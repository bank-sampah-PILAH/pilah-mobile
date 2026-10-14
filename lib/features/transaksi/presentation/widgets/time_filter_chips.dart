import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/report_export_sheet.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/filter_tanggal_bottom_sheet.dart';

/// Period chips, custom range, and setoran-only export for the unified
/// Riwayat Aktivitas screen (PIL-282). Export and the custom range operate
/// on setoran regardless of the type filter — pencairan has no backend
/// support for either.
class TimeFilterChips extends StatelessWidget {
  const TimeFilterChips({super.key});

  // Chip label → backend `periode` value.
  static const Map<String, String> _chips = {
    'Bulan Ini': 'bulan_ini',
    'Bulan Lalu': 'bulan_lalu',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiwayatAktivitasCubit, RiwayatAktivitasState>(
      buildWhen: (previous, current) =>
          previous.periode != current.periode ||
          previous.dariTanggal != current.dariTanggal ||
          previous.sampaiTanggal != current.sampaiTanggal,
      builder: (context, state) {
        final activePeriode = state.periode;
        return Row(
          children: [
            for (final entry in _chips.entries) ...[
              _buildFilterChip(context, entry.key, entry.value, activePeriode),
              const SizedBox(width: 6),
            ],
            const Spacer(),
            // Calendar Button (custom date range)
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider.value(
                    value: context.read<RiwayatAktivitasCubit>(),
                    child: const FilterTanggalBottomSheet(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activePeriode == 'custom'
                      ? AppColors.greenDark
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: activePeriode == 'custom'
                      ? Colors.white
                      : const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Export XLS Button
            InkWell(
              onTap: () => _onExport(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded,
                        color: Color(0xFF374151), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'XLS',
                      style: AppTextStyle.small.copyWith(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Downloads the report, then offers to share it — the app-wide
  /// save-then-share flow shared with the PDF export.
  Future<void> _onExport(BuildContext context) async {
    final cubit = context.read<RiwayatAktivitasCubit>();

    final loading = AppNotification.showLoading(
      context,
      title: 'Informasi',
      message: 'Menyiapkan laporan XLS...',
    );

    final (:export, :error) = await cubit.exportTransaksi();
    await loading.dismiss();
    if (!context.mounted) return;

    if (error != null) {
      AppNotification.showError(context, title: 'Gagal', message: error);
      return;
    }

    await saveAndOfferShare(
      context,
      filename: export!.filename,
      bytes: export.bytes,
      successMessage: (saved) =>
          'Laporan berhasil disimpan ke folder ${saved.folder}',
      shareText: 'Laporan Transaksi PILAH',
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String periode,
    String activePeriode,
  ) {
    final bool isSelected = activePeriode == periode;
    return GestureDetector(
      onTap: () {
        context.read<RiwayatAktivitasCubit>().setPeriode(periode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenDark : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
