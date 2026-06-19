import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/laporan/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/laporan/presentation/widgets/time_filter_chips.dart';
import 'package:pilah_mobile/features/laporan/presentation/widgets/transaction_list_view.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  static const route = '/laporan';

  @override
  Widget build(BuildContext context) {
    return const _LaporanPageBody();
  }
}

class _LaporanPageBody extends StatelessWidget {
  const _LaporanPageBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Semua Transaksi',
                        style: AppTextStyle.headline1.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  CustomSearchField(
                    hintText: 'Cari nama pelanggan...',
                    onChanged: (value) {
                      context.read<TransaksiCubit>().searchTransaksi(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Row
                  const TimeFilterChips(),
                ],
              ),
            ),
            
            // Scrollable List Section
            const Expanded(
              child: TransactionListView(),
            ),
          ],
        ),
      ),
    );
  }
}
