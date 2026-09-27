import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
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
              GestureDetector(
                onTap: () => context
                    .read<RiwayatAktivitasCubit>()
                    .setTipeFilter(entry.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: state.tipeFilter == entry.key
                        ? AppColors.greenDark
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.value,
                    style: AppTextStyle.small.copyWith(
                      color: state.tipeFilter == entry.key
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ],
        );
      },
    );
  }
}
