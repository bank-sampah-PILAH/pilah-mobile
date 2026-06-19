import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/laporan/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/laporan/presentation/cubit/transaksi_state.dart';
import 'package:pilah_mobile/features/laporan/presentation/widgets/filter_tanggal_bottom_sheet.dart';

class TimeFilterChips extends StatelessWidget {
  const TimeFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransaksiCubit, TransaksiState>(
      buildWhen: (previous, current) {
        if (previous is TransaksiLoaded && current is TransaksiLoaded) {
          return previous.activeFilter != current.activeFilter;
        }
        return true;
      },
      builder: (context, state) {
        final activeFilter = state is TransaksiLoaded ? state.activeFilter : 'Hari Ini';
        return Row(
          children: [
            _buildFilterChip(context, 'Hari Ini', activeFilter),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Minggu Ini', activeFilter),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Bulan Ini', activeFilter),
            const Spacer(),
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true, 
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const FilterTanggalBottomSheet(),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String activeFilter) {
    final bool isSelected = activeFilter == label;
    return GestureDetector(
      onTap: () {
        context.read<TransaksiCubit>().setFilter(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenDark : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
