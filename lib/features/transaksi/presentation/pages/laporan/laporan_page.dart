import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_list_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_tipe_chips.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/time_filter_chips.dart';

/// The unified Riwayat Aktivitas screen (PIL-282): setoran and pencairan in
/// one chronological feed, filterable by type and period. Previously
/// pencairan had its own separate "Riwayat Pencairan" screen and beranda
/// entry point.
class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  static const route = '/laporan';

  @override
  Widget build(BuildContext context) {
    return const _LaporanPageBody();
  }
}

class _LaporanPageBody extends StatefulWidget {
  const _LaporanPageBody();

  @override
  State<_LaporanPageBody> createState() => _LaporanPageBodyState();
}

class _LaporanPageBodyState extends State<_LaporanPageBody> {
  @override
  void initState() {
    super.initState();
    context.read<RiwayatAktivitasCubit>().load();
  }

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
                        'Riwayat Aktivitas',
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
                      context.read<RiwayatAktivitasCubit>().search(value);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Type filter: Semua / Setoran / Pencairan
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AktivitasTipeChips(),
                  ),
                  const SizedBox(height: 12),

                  // Period filter, custom range and setoran export
                  const TimeFilterChips(),
                ],
              ),
            ),

            // Scrollable List Section
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () =>
                    context.read<RiwayatAktivitasCubit>().load(silent: true),
                child: const AktivitasListView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
