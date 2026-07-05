import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/filter_tanggal_bottom_sheet.dart';

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
        final activeFilter = state is TransaksiLoaded ? state.activeFilter : 'Bulan Ini';
        return Row(
          children: [
            _buildFilterChip(context, 'Bulan Ini', activeFilter),
            const SizedBox(width: 6),
            _buildFilterChip(context, 'Bulan Lalu', activeFilter),
            const Spacer(),
            // Calendar Button
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
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Export XLS Button
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulasi: Mengunduh laporan XLS...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.download_rounded,
                      color: Color(0xFF374151),
                      size: 16,
                    ),
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

  Widget _buildFilterChip(BuildContext context, String label, String activeFilter) {
    final bool isSelected = activeFilter == label;
    return GestureDetector(
      onTap: () {
        context.read<TransaksiCubit>().setActiveFilter(label);
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
