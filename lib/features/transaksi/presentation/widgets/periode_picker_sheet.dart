import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/filter_tanggal_bottom_sheet.dart';

/// Pilihan periode bawaan Riwayat Aktivitas, dalam urutan tampil.
const periodePresets = <(String value, String label)>[
  ('hari_ini', 'Hari Ini'),
  ('minggu_ini', 'Minggu Ini'),
  ('bulan_ini', 'Bulan Ini'),
  ('bulan_lalu', 'Bulan Lalu'),
  ('1_bulan', '1 Bulan'),
  ('3_bulan', '3 Bulan'),
  ('6_bulan', '6 Bulan'),
  ('12_bulan', '12 Bulan'),
  ('semua', 'Semua Waktu'),
];

/// Nilai periode yang dipakai bila tidak ada yang dipilih.
const periodeBawaan = 'bulan_ini';

/// Teks pada tombol periode: nama pilihan, atau rentang tanggalnya.
String periodeLabel(RiwayatAktivitasState state) {
  if (state.isCustomPeriode &&
      state.dariTanggal != null &&
      state.sampaiTanggal != null) {
    return '${_tanggal(state.dariTanggal!)} – ${_tanggal(state.sampaiTanggal!)}';
  }
  return periodePresets
      .firstWhere(
        (p) => p.$1 == state.periode,
        orElse: () => periodePresets[2],
      )
      .$2;
}

String _tanggal(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Membuka pemilih periode: bottom sheet di telepon, dialog di layar lebar.
Future<void> showPeriodePicker(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showAdaptiveSurface<void>(
    context,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: const PeriodePickerSheet(),
    ),
  );
}

/// Semua pilihan periode dalam satu daftar, ditambah rentang tanggal sendiri.
/// Menggantikan sembilan chip periode dan tombol rentang tanggal.
class PeriodePickerSheet extends ConsumerWidget {
  const PeriodePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riwayatAktivitasProvider);
    return AppSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHeader(title: 'Pilih Periode'),
          const SizedBox(height: AppSpacing.lg),
          for (final (value, label) in periodePresets)
            _Option(
              label: label,
              selected: !state.isCustomPeriode && state.periode == value,
              onTap: () {
                ref.read(riwayatAktivitasProvider.notifier).setPeriode(value);
                Navigator.of(context).pop();
              },
            ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          _Option(
            label: 'Rentang tanggal…',
            icon: Icons.calendar_today_outlined,
            selected: state.isCustomPeriode,
            onTap: () {
              final container =
                  ProviderScope.containerOf(context, listen: false);
              final host = Navigator.of(context, rootNavigator: true).context;
              Navigator.of(context).pop();
              showAdaptiveSurface<void>(
                host,
                builder: (_) => UncontrolledProviderScope(
                  container: container,
                  child: const FilterTanggalBottomSheet(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.inkSoft),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyle.headline3.copyWith(
                    color: selected ? AppColors.greenDark : AppColors.black,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 20, color: AppColors.greenDark),
            ],
          ),
        ),
      ),
    );
  }
}
