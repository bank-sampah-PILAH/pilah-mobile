import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_activity_card.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/pencairan/presentation/providers/riwayat_pencairan_provider.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_state.dart';

import '../../domain/model/riwayat_pencairan_filter.dart';
import 'pencairan_detail_sheet.dart';

class PencairanHistoryTab extends ConsumerStatefulWidget {
  const PencairanHistoryTab({super.key});

  @override
  ConsumerState<PencairanHistoryTab> createState() =>
      _PencairanHistoryTabState();
}

class _PencairanHistoryTabState extends ConsumerState<PencairanHistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(riwayatPencairanProvider.notifier).load(
              const RiwayatPencairanFilter(periode: RiwayatPeriode.semua),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riwayatPencairanProvider);
    final notifier = ref.read(riwayatPencairanProvider.notifier);
    return AppRefreshIndicator(
      onRefresh: () => notifier.load(state.filter),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Riwayat Pencairan',
                  style: NasabahStyle.text(20, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: () => notifier.load(state.filter),
                icon: const Icon(Icons.refresh),
                color: NasabahStyle.emerald,
              ),
            ],
          ),
          Text(
            'Daftar pencairan yang tercatat pada akun Anda.',
            style: NasabahStyle.text(13, color: NasabahStyle.muted),
          ),
          const SizedBox(height: 16),
          if (state.items.isNotEmpty)
            for (final item in state.items)
              NasabahActivityCard(
                title: 'Pencairan',
                date: item.tanggal,
                amount: nasabahRupiah(item.nominal.toString()),
                isWithdrawal: true,
                onTap: () => showNasabahPencairanDetailSheet(context, item),
              ),
          if (state.status == RiwayatStatus.loading && state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: NasabahStyle.emerald),
              ),
            )
          else if (state.status == RiwayatStatus.failure && state.items.isEmpty)
            NasabahCard(
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      color: NasabahStyle.muted, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? 'Riwayat gagal dimuat.',
                    textAlign: TextAlign.center,
                    style: NasabahStyle.text(13),
                  ),
                  TextButton(
                    onPressed: () => notifier.load(state.filter),
                    child: Text(
                      'Coba Lagi',
                      style: NasabahStyle.text(
                        13,
                        weight: FontWeight.w600,
                        color: NasabahStyle.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (state.status == RiwayatStatus.loaded && state.items.isEmpty)
            const NasabahCard(
              child: Center(child: Text('Belum ada riwayat pencairan')),
            ),
          if (state.status == RiwayatStatus.loading && state.items.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: NasabahStyle.emerald),
              ),
            ),
        ],
      ),
    );
  }
}
