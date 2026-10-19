import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/revisi_pencairan.dart';
import '../blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';

/// Pengurus-only change history of one pencairan (PIL-230): the current
/// version, then every replaced version with why, who and when.
class RevisiPencairanPage extends StatelessWidget {
  static const route = '/riwayat-perubahan-pencairan';

  final String pencairanId;

  const RevisiPencairanPage({super.key, required this.pencairanId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<RevisiPencairanCubit>(),
      child: RevisiPencairanView(pencairanId: pencairanId),
    );
  }
}

class RevisiPencairanView extends StatefulWidget {
  final String pencairanId;

  /// Inside a dialog on a wide window: no page scaffold or back header.
  final bool embedded;

  /// With [embedded]: whether to draw its own title and close button.
  final bool showHeader;

  const RevisiPencairanView({
    super.key,
    required this.pencairanId,
    this.embedded = false,
    this.showHeader = true,
  });

  @override
  State<RevisiPencairanView> createState() => _RevisiPencairanViewState();
}

class _RevisiPencairanViewState extends State<RevisiPencairanView> {
  @override
  void initState() {
    super.initState();
    context.read<RevisiPencairanCubit>().load(widget.pencairanId);
  }

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<RevisiPencairanCubit, RevisiPencairanState>(
      builder: (context, state) {
        switch (state.status) {
          case RevisiStatus.loading:
            return const Center(
              heightFactor: 4,
              child: CircularProgressIndicator(),
            );
          case RevisiStatus.failure:
            return Center(
              heightFactor: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Gagal memuat riwayat'),
                  TextButton(
                    onPressed: () => context
                        .read<RevisiPencairanCubit>()
                        .load(widget.pencairanId),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          case RevisiStatus.loaded:
            final riwayat = state.riwayat!;
            final perubahan = _perubahan(riwayat);
            // The list spans the body, so its scrollbar is at the window edge;
            // the frame keeps the cards to a form's column.
            return ContentFrame(
              maxWidth: LayoutBreakpoint.formMaxWidth,
              child: Builder(
                builder: (context) => ListView(
                  shrinkWrap: widget.embedded,
                  padding: ContentFrame.insetOf(context).add(
                    EdgeInsets.symmetric(
                        horizontal: widget.embedded ? 0 : 16, vertical: 8),
                  ),
                  children: [
                    _SekarangCard(pencairan: riwayat.pencairan),
                    const SizedBox(height: AppSpacing.lg),
                    AppFieldLabel('PERUBAHAN (${perubahan.length})'),
                    const SizedBox(height: AppSpacing.md),
                    for (final item in perubahan)
                      _PerubahanCard(perubahan: item),
                  ],
                ),
              ),
            );
        }
      },
    );

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader)
            AppPanelHeader(
              title: 'Riwayat Perubahan',
              onClose: () => Navigator.of(context).maybePop(),
            ),
          Flexible(child: body),
        ],
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppBackHeader(title: 'Riwayat Perubahan'),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Satu perubahan: apa yang berbeda dari versi lama ke versi sesudahnya,
/// dengan alasan, siapa, dan kapan.
class _Perubahan {
  const _Perubahan({required this.versi, required this.baris});

  final RevisiPencairan versi;
  final List<(String label, String lama, String baru)> baris;
}

/// Pasangkan tiap versi lama dengan versi yang menggantikannya. Daftar revisi
/// dari yang terbaru, jadi pengganti versi ke-i adalah versi ke-(i-1), atau
/// versi sekarang untuk yang pertama.
List<_Perubahan> _perubahan(RiwayatRevisiPencairan riwayat) {
  final revisi = riwayat.revisi;
  return [
    for (var i = 0; i < revisi.length; i++)
      _Perubahan(
        versi: revisi[i],
        baris: _selisih(
            revisi[i], i == 0 ? null : revisi[i - 1], riwayat.pencairan),
      ),
  ];
}

/// Nilai yang berbeda antara versi [lama] dan penggantinya: revisi sesudahnya,
/// atau [sekarang] bila tidak ada.
List<(String label, String lama, String baru)> _selisih(
  RevisiPencairan lama,
  RevisiPencairan? pengganti,
  Pencairan sekarang,
) {
  final nominal = pengganti?.nominal ?? sekarang.nominal;
  final metode = pengganti?.metode ?? sekarang.metode;
  final tanggal = pengganti?.tanggal ?? sekarang.tanggal;
  final keterangan = pengganti?.keterangan ?? sekarang.keterangan;
  String rp(int v) => 'Rp ${CurrencyFormatter.formatNumber(v)}';
  String ket(String v) => v.isEmpty ? '-' : v;
  return [
    if (lama.nominal != nominal) ('Nominal', rp(lama.nominal), rp(nominal)),
    if (lama.metode != metode) ('Metode', lama.metode.label, metode.label),
    if (lama.tanggal != tanggal)
      ('Tanggal', _waktu(lama.tanggal), _waktu(tanggal)),
    if (lama.keterangan != keterangan)
      ('Keterangan', ket(lama.keterangan), ket(keterangan)),
  ];
}

class _SekarangCard extends StatelessWidget {
  const _SekarangCard({required this.pencairan});

  final Pencairan pencairan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppFieldLabel('VERSI SEKARANG'),
            const SizedBox(height: 4),
            Text(
              'Rp ${CurrencyFormatter.formatNumber(pencairan.nominal)}',
              style: AppTextStyle.title1.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: 8),
            AppDetailRow(label: 'Metode', value: pencairan.metode.label),
            AppDetailRow(label: 'Tanggal', value: _waktu(pencairan.tanggal)),
            if (pencairan.keterangan.isNotEmpty)
              AppDetailRow(label: 'Keterangan', value: pencairan.keterangan),
          ],
        ),
      ),
    );
  }
}

class _PerubahanCard extends StatelessWidget {
  const _PerubahanCard({required this.perubahan});

  final _Perubahan perubahan;

  @override
  Widget build(BuildContext context) {
    final versi = perubahan.versi;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mengganti versi ${versi.versi}',
            style: AppTextStyle.small.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Diubah oleh ${versi.diubahOlehNama} · ${_waktu(versi.diubahPada)}',
            style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
          ),
          const SizedBox(height: AppSpacing.md),
          if (perubahan.baris.isEmpty)
            Text('Tidak ada nilai yang berubah.',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100))
          else
            for (final (label, lama, baru) in perubahan.baris)
              _DiffRow(label: label, lama: lama, baru: baru),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              versi.alasan,
              style: AppTextStyle.small.copyWith(color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.label, required this.lama, required this.baru});

  final String label;
  final String lama;
  final String baru;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyle.small.copyWith(color: AppColors.black);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: base.copyWith(color: AppColors.grey100)),
          ),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                text: lama,
                style: base.copyWith(
                  color: AppColors.grey100,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              TextSpan(text: '  →  ', style: base),
              TextSpan(
                text: baru,
                style: base.copyWith(fontWeight: FontWeight.w600),
              ),
            ])),
          ),
        ],
      ),
    );
  }
}

String _waktu(DateTime? waktu) =>
    waktu == null ? '-' : formatTanggalJamId(waktu);
