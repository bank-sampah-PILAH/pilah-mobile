import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_summary_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_detail_sheet.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/detail_transaksi_bottom_sheet.dart';

/// Renders the merged setoran + pencairan feed (PIL-282), grouped by day.
/// Tapping a row opens that type's own detail sheet — setoran's
/// [DetailTransaksiBottomSheet], pencairan's [showPencairanDetailSheet] with
/// its Pengurus-only edit/riwayat-perubahan entry points.
/// Jarak area gulir daftar kartu di telepon: batas lebar dari `ContentFrame`
/// (nol di telepon) dan ruang di bawah baris terakhir.
EdgeInsetsGeometry _scrollPadding(BuildContext context,
        {required double bottom}) =>
    ContentFrame.insetOf(context).add(EdgeInsets.only(bottom: bottom));

class AktivitasListView extends StatelessWidget {
  final DateTime Function() now;
  final bool isWeb;

  const AktivitasListView({
    super.key,
    this.now = DateTime.now,
    this.isWeb = kIsWeb,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiwayatAktivitasCubit, RiwayatAktivitasState>(
      builder: (context, state) {
        if (state.status == AktivitasStatus.initial ||
            state.status == AktivitasStatus.loading) {
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: _scrollPadding(context, bottom: 80),
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => const SkeletonListItem(),
          );
        }

        if (state.status == AktivitasStatus.failure) {
          return Column(children: [
            Expanded(
                child: EmptyView(
                    title: 'Gagal Memuat Data',
                    subtitle: state.errorMessage ?? 'Terjadi kesalahan',
                    icon: Icons.error_outline)),
            TextButton(
                onPressed: () => context.read<RiwayatAktivitasCubit>().load(),
                child: const Text('Coba Lagi')),
          ]);
        }

        if (state.items.isEmpty) {
          return EmptyView(
            title: state.search.isNotEmpty
                ? 'Aktivitas Tidak Ditemukan'
                : 'Belum Ada Aktivitas',
            subtitle: state.search.isNotEmpty
                ? 'Coba kata kunci atau nama pelanggan lain'
                : 'Belum ada aktivitas tercatat pada periode ini.',
            icon: Icons.receipt_long_outlined,
          );
        }

        final footer = _footer(context, state);
        final wide = context.layoutBreakpoint != LayoutBreakpoint.compact;
        Widget scrollNotifications(Widget child) =>
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (!isWeb &&
                    notification.metrics.axis == Axis.vertical &&
                    notification.metrics.extentAfter < 200 &&
                    state.errorMessage == null) {
                  context.read<RiwayatAktivitasCubit>().loadMore();
                }
                return false;
              },
              child: child,
            );
        if (wide) {
          // Halaman data: tabel sebagai kartu yang mengisi sisa tinggi layar,
          // hanya barisnya yang bergulir, dan paginasi di dasar kartu.
          final side = ContentFrame.insetOf(context).add(
              const EdgeInsets.symmetric(horizontal: AppSpacing.webGutter));
          return scrollNotifications(
            Padding(
              padding: side.add(const EdgeInsets.only(bottom: AppSpacing.xl)),
              child: AktivitasTable(
                items: state.items,
                onTap: (item) => _openDetail(context, item),
                footer: footer,
                toolbar: const AktivitasSummaryStrip(),
                pagination: isWeb
                    ? WebPaginationBar(
                        currentPage: state.currentPage,
                        totalItems: state.totalCount,
                        pageSize: state.pageSize,
                        itemLabel: 'transaksi',
                        onPageChanged:
                            context.read<RiwayatAktivitasCubit>().loadPage,
                      )
                    : null,
              ),
            ),
          );
        }
        final cards = scrollNotifications(
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: _scrollPadding(context, bottom: 24),
            children: _groupedRows(state, now(), footer),
          ),
        );
        if (!isWeb) return cards;
        // Browser sempit: kartu satu kolom, paginasi di bawahnya.
        return Column(
          children: [
            Expanded(child: cards),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WebPaginationBar(
                currentPage: state.currentPage,
                totalItems: state.totalCount,
                pageSize: state.pageSize,
                itemLabel: 'transaksi',
                onPageChanged: context.read<RiwayatAktivitasCubit>().loadPage,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Baris yang dikelompokkan per hari, untuk telepon.
  List<Widget> _groupedRows(
    RiwayatAktivitasState state,
    DateTime today,
    List<Widget> footer,
  ) {
    final children = <Widget>[];
    String? lastHeader;
    for (final item in state.items) {
      final header = _dayHeader(item.tanggal, today);
      if (header != lastHeader) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            header,
            style: AppTextStyle.extraSmall.copyWith(
              color: AppColors.grey100,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ));
        lastHeader = header;
      }
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _AktivitasRow(item: item),
      ));
    }
    return [...children, ...footer];
  }

  /// Indikator muat atau tombol "Muat Lagi" di bawah baris terakhir.
  List<Widget> _footer(BuildContext context, RiwayatAktivitasState state) {
    if (state.loadingMore) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }
    if (isWeb && state.retryPage == null) return const [];
    if (!state.hasNext && state.retryPage == null) return const [];
    return [
      TextButton(
        onPressed: () {
          final cubit = context.read<RiwayatAktivitasCubit>();
          final retryPage = state.retryPage;
          if (retryPage == null) {
            cubit.loadMore();
          } else {
            cubit.loadPage(retryPage);
          }
        },
        child: Text(state.errorMessage == null ? 'Muat Lagi' : 'Coba Lagi'),
      ),
      if (state.errorMessage != null)
        Text(state.errorMessage!, textAlign: TextAlign.center),
    ];
  }

  String _dayHeader(DateTime? tanggal, DateTime today) {
    if (tanggal == null) return 'LAINNYA';
    final diff = DateUtils.dateOnly(today)
        .difference(DateUtils.dateOnly(tanggal))
        .inDays;
    if (diff <= 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return '$diff HARI LALU';
  }
}

/// Membuka detail sebuah aktivitas: lembar setoran atau lembar pencairan.
void _openDetail(BuildContext context, ActivitasEntity item) {
  if (item.tipe == ActivitasTipe.setoran) {
    final t = item.transaksi!;
    showAdaptiveSurface<void>(
      context,
      builder: (context) => DetailTransaksiBottomSheet(
        transactionData: {
          'id': t.id,
          'initials': t.initials,
          'avatarColor': t.avatarColor,
          'textColor': t.textColor,
          'name': t.name,
          'time': t.time ?? 'Hari ini',
          'amount': t.amount,
          'balance': t.balance,
          'waStatus': t.isWaSuccess ? 'sent' : 'failed',
          'items': t.items
              .map((i) => {
                    'jenis': i.jenis,
                    'berat': i.berat,
                    'harga': i.harga,
                    'subtotal': i.subtotal,
                  })
              .toList(),
        },
      ),
    );
  } else {
    showPencairanDetailSheet(
      context,
      item.pencairan!,
      onChanged: () => context.read<RiwayatAktivitasCubit>().load(silent: true),
    );
  }
}

class _AktivitasRow extends StatelessWidget {
  final ActivitasEntity item;

  const _AktivitasRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _openDetail(context, item),
      child: ActivityItem(
        avatarText: item.avatarText,
        avatarColor: item.avatarColor,
        avatarTextColor: item.avatarTextColor,
        title: item.title,
        subtitleLines: item.subtitleLines,
        amount: item.amount,
        amountColor: item.amountColor,
        trailingCaptions: item.trailingCaptions,
        badge: item.badge,
      ),
    );
  }
}
