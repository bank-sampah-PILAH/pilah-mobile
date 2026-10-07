import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_detail_sheet.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/detail_transaksi_bottom_sheet.dart';

/// Renders the merged setoran + pencairan feed (PIL-282), grouped by day.
/// Tapping a row opens that type's own detail sheet — setoran's
/// [DetailTransaksiBottomSheet], pencairan's [showPencairanDetailSheet] with
/// its Pengurus-only edit/riwayat-perubahan entry points.
class AktivitasListView extends StatelessWidget {
  final DateTime Function() now;

  const AktivitasListView({super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiwayatAktivitasCubit, RiwayatAktivitasState>(
      builder: (context, state) {
        if (state.status == AktivitasStatus.initial ||
            state.status == AktivitasStatus.loading) {
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
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

        final today = now();
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
                  color: Colors.grey[500],
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
        if (state.loadingMore) {
          children.add(const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator())));
        } else if (state.hasNext) {
          children.add(TextButton(
              onPressed: () => context.read<RiwayatAktivitasCubit>().loadMore(),
              child: Text(
                  state.errorMessage == null ? 'Muat Lagi' : 'Coba Lagi')));
          if (state.errorMessage != null) {
            children
                .add(Text(state.errorMessage!, textAlign: TextAlign.center));
          }
        }
        return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter < 200 &&
                  state.errorMessage == null) {
                context.read<RiwayatAktivitasCubit>().loadMore();
              }
              return false;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: children,
            ));
      },
    );
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

class _AktivitasRow extends StatelessWidget {
  final ActivitasEntity item;

  const _AktivitasRow({required this.item});

  void _onTap(BuildContext context) {
    if (item.tipe == ActivitasTipe.setoran) {
      final t = item.transaksi!;
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
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
        onChanged: () =>
            context.read<RiwayatAktivitasCubit>().load(silent: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onTap(context),
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
