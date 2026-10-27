import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/page_state_view.dart';
import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/riwayat_harga_provider.dart';

/// Riwayat harga satu jenis sampah sebagai linimasa, terbaru di atas.
///
/// Hanya isinya, tanpa Scaffold, supaya sama di halaman, di panel samping, dan
/// di bottom sheet. Loads the shared auto-dispose Riverpod provider.
class RiwayatHargaContent extends ConsumerStatefulWidget {
  const RiwayatHargaContent({super.key, required this.jenisId});

  final String jenisId;

  @override
  ConsumerState<RiwayatHargaContent> createState() =>
      _RiwayatHargaContentState();
}

class _RiwayatHargaContentState extends ConsumerState<RiwayatHargaContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(riwayatHargaProvider.notifier).load(widget.jenisId);
    });
  }

  @override
  void didUpdateWidget(covariant RiwayatHargaContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jenisId != widget.jenisId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(riwayatHargaProvider.notifier).load(widget.jenisId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riwayatHargaProvider);
    final pageState = switch (state.status) {
      RiwayatHargaStatus.loading => PageState.loading,
      RiwayatHargaStatus.failure => PageState.error,
      RiwayatHargaStatus.loaded =>
        state.riwayat.isEmpty ? PageState.empty : PageState.ready,
    };
    return PageStateView(
      state: pageState,
      errorMessage: state.errorMessage,
      onRetry: () =>
          ref.read(riwayatHargaProvider.notifier).load(widget.jenisId),
      emptyTitle: 'Belum Ada Riwayat Harga',
      emptySubtitle: 'Harga yang diatur untuk jenis ini akan tampil di sini.',
      emptyIcon: Icons.history,
      skeletonCount: 3,
      child: _Timeline(riwayat: state.riwayat),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.riwayat});

  final List<VersiHarga> riwayat;

  /// Harga versi sebelum [index]: yang terdekat di bawahnya yang pernah atau
  /// akan berlaku. Versi "digantikan" tidak pernah berlaku, jadi tidak
  /// menjadi pembanding dan tidak punya selisih sendiri.
  int? _pembanding(int index) {
    for (var i = index + 1; i < riwayat.length; i++) {
      if (riwayat[i].status != StatusVersiHarga.digantikan) {
        return riwayat[i].hargaSen;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final perubahan =
        riwayat.where((v) => v.status != StatusVersiHarga.digantikan).length;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(
            '$perubahan versi harga tercatat',
            style: AppTextStyle.small.copyWith(color: AppColors.grey100),
          ),
        ),
        for (var i = 0; i < riwayat.length; i++)
          _Entry(
            versi: riwayat[i],
            pembanding: riwayat[i].status == StatusVersiHarga.digantikan
                ? null
                : _pembanding(i),
            last: i == riwayat.length - 1,
          ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.versi,
    required this.pembanding,
    required this.last,
  });

  final VersiHarga versi;
  final int? pembanding;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (label, latar, warna) = _gayaStatus(versi.status);
    final oleh = versi.dibuatOleh;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6),
                _Dot(status: versi.status),
                if (!last)
                  const Expanded(
                    child: VerticalDivider(
                      width: 2,
                      thickness: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${CurrencyFormatter.formatRupiahSen(versi.hargaSen)} / ${versi.satuan}',
                          style: AppTextStyle.title1.copyWith(
                            color: versi.status == StatusVersiHarga.digantikan
                                ? AppColors.grey100
                                : AppColors.black,
                            decoration:
                                versi.status == StatusVersiHarga.digantikan
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                      ),
                      CustomStatusBadge(
                        statusText: label,
                        backgroundColor: latar,
                        textColor: warna,
                      ),
                    ],
                  ),
                  if (pembanding != null && pembanding != versi.hargaSen)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: _Selisih(
                        sen: versi.hargaSen - pembanding!,
                        dari: pembanding!,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Mulai ${formatTanggalJamId(versi.berlakuMulai.toLocal())}',
                    style:
                        AppTextStyle.small.copyWith(color: AppColors.inkSoft),
                  ),
                  Text(
                    oleh == null
                        ? 'Harga awal dari data lama'
                        : 'Dicatat oleh $oleh',
                    style: AppTextStyle.extraSmall
                        .copyWith(color: AppColors.grey100),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selisih terhadap versi sebelumnya, mis. `▲ Rp 500 (+14%)`.
class _Selisih extends StatelessWidget {
  const _Selisih({required this.sen, required this.dari});

  final int sen;
  final int dari;

  @override
  Widget build(BuildContext context) {
    final naik = sen > 0;
    final persen = (sen.abs() * 100 / dari).round();
    return Text(
      '${naik ? '▲' : '▼'} ${CurrencyFormatter.formatRupiahSen(sen.abs())} '
      '(${naik ? '+' : '-'}$persen%)',
      style: AppTextStyle.small.copyWith(
        color: naik ? AppColors.greenDark : AppColors.danger,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.status});

  final StatusVersiHarga status;

  @override
  Widget build(BuildContext context) {
    final (fill, border) = switch (status) {
      StatusVersiHarga.berlaku => (AppColors.greenDark, AppColors.greenDark),
      StatusVersiHarga.terjadwal => (Colors.white, AppColors.warning),
      _ => (AppColors.border, AppColors.border),
    };
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
    );
  }
}

(String, Color, Color) _gayaStatus(StatusVersiHarga status) {
  switch (status) {
    case StatusVersiHarga.terjadwal:
      return ('Terjadwal', AppColors.warningLight, AppColors.warning);
    case StatusVersiHarga.berlaku:
      return ('Berlaku sekarang', AppColors.greenLight, AppColors.greenDark);
    case StatusVersiHarga.sebelumnya:
      return ('Sebelumnya', AppColors.fill, AppColors.inkSoft);
    case StatusVersiHarga.digantikan:
      return ('Digantikan', AppColors.fill, AppColors.grey100);
  }
}
