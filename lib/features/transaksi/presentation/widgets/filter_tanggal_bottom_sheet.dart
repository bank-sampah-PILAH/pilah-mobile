import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_calendar_range_picker.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';

class FilterTanggalBottomSheet extends StatefulWidget {
  const FilterTanggalBottomSheet({super.key});

  @override
  State<FilterTanggalBottomSheet> createState() =>
      _FilterTanggalBottomSheetState();
}

class _FilterTanggalBottomSheetState extends State<FilterTanggalBottomSheet> {
  static const Color mintTint = AppColors.greenLight;

  late DateTimeRange _initialRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final state = context.read<RiwayatAktivitasCubit>().state;
    final start = state.dariTanggal ?? DateTime(now.year, now.month, 1);
    final end = state.sampaiTanggal ?? DateTime(now.year, now.month + 1, 0);
    _initialRange = start.isAfter(end)
        ? DateTimeRange(start: end, end: start)
        : DateTimeRange(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHeader(title: 'Pilih Rentang Waktu'),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) => AppCalendarRangePicker(
              initialRange: _initialRange,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              applyLabel: 'Terapkan Filter',
              width: constraints.maxWidth.clamp(0.0, 336.0).toDouble(),
              onApply: (range) {
                context
                    .read<RiwayatAktivitasCubit>()
                    .applyCustomRange(range.start, range.end);
                context.pop();
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mintTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.greenDark, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filter akan diterapkan ke daftar transaksi.',
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
