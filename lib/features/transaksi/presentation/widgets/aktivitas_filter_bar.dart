import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_icon_button.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_export_action.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/periode_picker_sheet.dart';

/// Semua penyaring Riwayat Aktivitas dalam satu baris: tipe, periode, dan
/// ekspor. Menggantikan tiga chip tipe, sembilan chip periode, tombol rentang
/// tanggal, dan tombol XLSX yang dulu memenuhi tiga baris.
class AktivitasFilterBar extends ConsumerWidget {
  const AktivitasFilterBar({super.key});

  static const tipeLabels = {
    AktivitasTipeFilter.semua: 'Semua',
    AktivitasTipeFilter.setoran: 'Setoran',
    AktivitasTipeFilter.pencairan: 'Pencairan',
  };

  static bool _bukanBawaan(RiwayatAktivitasState s) =>
      s.tipeFilter != AktivitasTipeFilter.semua ||
      s.periode != periodeBawaan ||
      s.search.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riwayatAktivitasProvider);
    final tipe = _TipeSegments(state: state);
    final periode = _PeriodeButton(state: state);
    final reset = _bukanBawaan(state)
        ? AppButton(
            label: 'Reset',
            variant: AppButtonVariant.text,
            size: AppButtonSize.compact,
            expand: false,
            onPressed: () =>
                ref.read(riwayatAktivitasProvider.notifier).resetFilters(),
          )
        : null;
    return LayoutBuilder(builder: (context, constraints) {
      if (LayoutBreakpoint.fromWidth(constraints.maxWidth) !=
          LayoutBreakpoint.compact) {
        return Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [tipe, periode, if (reset != null) reset],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'Ekspor XLSX',
              icon: Icons.download_rounded,
              variant: AppButtonVariant.outlined,
              expand: false,
              onPressed: () => exportAktivitasReport(context),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tipe,
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _PeriodeField(state: state)),
              if (_bukanBawaan(state)) ...[
                const SizedBox(width: AppSpacing.sm),
                AppIconButton(
                  icon: Icons.restart_alt,
                  tooltip: 'Reset filter',
                  onPressed: () => ref
                      .read(riwayatAktivitasProvider.notifier)
                      .resetFilters(),
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: Icons.download_rounded,
                tooltip: 'Ekspor XLSX',
                onPressed: () => exportAktivitasReport(context),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _TipeSegments extends ConsumerWidget {
  const _TipeSegments({required this.state});

  final RiwayatAktivitasState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<AktivitasTipeFilter>(
      showSelectedIcon: false,
      segments: [
        for (final entry in AktivitasFilterBar.tipeLabels.entries)
          ButtonSegment(value: entry.key, label: Text(entry.value)),
      ],
      selected: {state.tipeFilter},
      onSelectionChanged: (selection) => ref
          .read(riwayatAktivitasProvider.notifier)
          .setTipeFilter(selection.first),
    );
  }
}

class _PeriodeButton extends StatelessWidget {
  const _PeriodeButton({required this.state});

  final RiwayatAktivitasState state;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: periodeLabel(state),
      icon: Icons.calendar_today_outlined,
      trailingIcon: Icons.arrow_drop_down,
      variant: AppButtonVariant.outlined,
      expand: false,
      onPressed: () => showPeriodePicker(context),
    );
  }
}

/// Periode di telepon: kolom pilihan putih seperti field lain, label di kiri
/// dan panah di kanan, sehingga terbaca sebagai pilihan, bukan aksi.
class _PeriodeField extends StatelessWidget {
  const _PeriodeField({required this.state});

  final RiwayatAktivitasState state;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => showPeriodePicker(context),
          child: SizedBox(
            height: AppButton.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.inkSoft),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      periodeLabel(state),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
