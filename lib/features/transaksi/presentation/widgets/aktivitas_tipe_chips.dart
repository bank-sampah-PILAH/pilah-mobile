import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';

/// Narrows the merged Riwayat Aktivitas feed to setoran, pencairan, or both
/// (PIL-282).
class AktivitasTipeChips extends StatelessWidget {
  const AktivitasTipeChips({super.key});

  static const _labels = {
    AktivitasTipeFilter.semua: 'Semua',
    AktivitasTipeFilter.setoran: 'Setoran',
    AktivitasTipeFilter.pencairan: 'Pencairan',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiwayatAktivitasCubit, RiwayatAktivitasState>(
      buildWhen: (previous, current) =>
          previous.tipeFilter != current.tipeFilter,
      builder: (context, state) {
        return Row(
          children: [
            for (final entry in _labels.entries) ...[
              AppChip(
                label: entry.value,
                selected: state.tipeFilter == entry.key,
                onTap: () => context
                    .read<RiwayatAktivitasCubit>()
                    .setTipeFilter(entry.key),
              ),
              const SizedBox(width: 6),
            ],
          ],
        );
      },
    );
  }
}
