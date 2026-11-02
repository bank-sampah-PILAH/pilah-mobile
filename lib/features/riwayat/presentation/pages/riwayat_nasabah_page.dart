import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/riwayat/presentation/providers/riwayat_history_provider.dart';
import 'package:pilah_mobile/features/riwayat/presentation/widgets/nasabah_setoran_detail_sheet.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// The Setoran tab, scoped by the host screen to one membership.
class RiwayatNasabahPage extends ConsumerStatefulWidget {
  const RiwayatNasabahPage({super.key, required this.membershipId});

  final String membershipId;

  @override
  ConsumerState<RiwayatNasabahPage> createState() => _RiwayatNasabahPageState();
}

class _RiwayatNasabahPageState extends ConsumerState<RiwayatNasabahPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(riwayatHistoryProvider.notifier).loadHistory(
              widget.membershipId,
              reset: true,
            );
      }
    });
  }

  void _showDetail(BuildContext context, String activityId) {
    final notifier = ref.read(riwayatHistoryProvider.notifier);
    showAdaptiveSurface<void>(
      context,
      builder: (sheetContext) => NasabahSetoranDetailSheet(
        loadDetail: () => notifier.loadDetail(widget.membershipId, activityId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riwayatHistoryProvider);
    final notifier = ref.read(riwayatHistoryProvider.notifier);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: NasabahStyle.maxWidth),
        child: RefreshIndicator(
          // Refresh means re-ask page 1: reset:false would request the
          // page after the last one and append its rows below.
          onRefresh: () => notifier.loadHistoryCurrent(reset: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Riwayat Setoran',
                      style:
                          NasabahStyle.text(20, weight: AppFontWeight.semibold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: state.status == RiwayatHistoryStatus.loading
                        ? null
                        : () => notifier.loadHistoryCurrent(reset: true),
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
                        onPressed: () => notifier.loadHistoryCurrent(),
                        child: Text(
                          'Coba Lagi',
                          style: NasabahStyle.text(
                            13,
                            weight: AppFontWeight.semibold,
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
                            NasabahStyle.text(14, weight: AppFontWeight.medium),
                      ),
                    ],
                  ),
                ),
              if (state.status != RiwayatHistoryStatus.loading &&
                  state.error == null &&
                  state.hasNext)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppButton(
                    label: 'Muat Lagi',
                    icon: Icons.expand_more,
                    onPressed: () => notifier.loadHistoryCurrent(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
