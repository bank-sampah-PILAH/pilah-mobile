import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
import 'package:pilah_mobile/features/riwayat/presentation/widgets/nasabah_setoran_detail_sheet.dart';

/// The Setoran tab: reads [RiwayatHistoryCubit] (provided by the host
/// screen scoped to one membership) and renders loading/empty/error/list.
/// Row taps open the itemized detail bottom sheet, which loads through the
/// same cubit.
class RiwayatNasabahPage extends StatelessWidget {
  const RiwayatNasabahPage({super.key});

  void _showDetail(BuildContext context, String activityId) {
    final cubit = context.read<RiwayatHistoryCubit>();
    final membershipId = cubit.membershipId ?? '';
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => NasabahSetoranDetailSheet(
        loadDetail: () => cubit.loadDetail(membershipId, activityId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: NasabahStyle.maxWidth),
          child: RefreshIndicator(
            onRefresh: () => context
                .read<RiwayatHistoryCubit>()
                .loadHistoryCurrent(reset: true),
            child: BlocBuilder<RiwayatHistoryCubit, RiwayatHistoryState>(
              builder: (context, state) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Riwayat Setoran',
                          style: NasabahStyle.text(20, weight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Muat ulang',
                        onPressed: state.status == RiwayatHistoryStatus.loading
                            ? null
                            : () => context
                                .read<RiwayatHistoryCubit>()
                                .loadHistoryCurrent(reset: true),
                        icon: const Icon(Icons.refresh),
                        color: NasabahStyle.emerald,
                      ),
                    ],
                  ),
                  Text(
                    'Daftar aktivitas yang tercatat pada keanggotaan ini.',
                    style: NasabahStyle.text(13, color: NasabahStyle.muted),
                  ),
                  const SizedBox(height: 16),
                  if (state.activities.isNotEmpty)
                    NasabahActivityList(
                      activities: state.activities,
                      onTap: (activity) => _showDetail(context, activity.id),
                    ),
                  if (state.status == RiwayatHistoryStatus.loading)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: NasabahStyle.emerald)))
                  else if (state.error != null) ...[
                    NasabahCard(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_outlined,
                              color: NasabahStyle.muted, size: 28),
                          const SizedBox(height: 8),
                          Text(state.error!,
                              textAlign: TextAlign.center,
                              style: NasabahStyle.text(13)),
                          TextButton(
                            onPressed: () => context
                                .read<RiwayatHistoryCubit>()
                                .loadHistoryCurrent(),
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
                    ),
                  ] else if (state.activities.isEmpty)
                    NasabahCard(
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              color: NasabahStyle.emerald, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada aktivitas',
                            textAlign: TextAlign.center,
                            style:
                                NasabahStyle.text(14, weight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  if (state.status != RiwayatHistoryStatus.loading &&
                      state.error == null &&
                      state.hasNext)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: NasabahStyle.emerald,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => context
                            .read<RiwayatHistoryCubit>()
                            .loadHistoryCurrent(),
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          'Muat Lagi',
                          style: NasabahStyle.text(
                            14,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
