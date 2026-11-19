import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/services/di.dart';

/// Reloads from the membership-scoped endpoint, including after a web refresh.
/// No schedule data or permission decision is taken from router extras.
class NasabahJadwalDetailPage extends ConsumerWidget {
  const NasabahJadwalDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authenticationProvider);
    return Scaffold(
      appBar: const NasabahPageAppBar(title: 'Detail Jadwal', showBack: true),
      body: auth is! Authenticated || auth.authEntity.role != 'nasabah'
          ? const Center(child: Text('Silakan masuk sebagai nasabah.'))
          : ContentFrame(
              maxWidth: LayoutBreakpoint.formMaxWidth,
              child: Builder(
                  builder: (context) => ListView(
                        padding: ContentFrame.insetOf(context).add(
                          const EdgeInsets.all(AppSpacing.md),
                        ),
                        children: [
                          NasabahResource<JadwalEntity>(
                            key: ValueKey((
                              id,
                              auth.authEntity.id,
                              auth.authEntity.token
                            )),
                            load: () async =>
                                (await di<JadwalRepository>().getDetail(id))
                                    .fold(
                              (error) => throw NasabahApiException(
                                {403, 404}.contains(error.response?.statusCode)
                                    ? 'Jadwal tidak tersedia.'
                                    : 'Jadwal gagal dimuat. Silakan coba lagi.',
                              ),
                              (schedule) => schedule,
                            ),
                            builder: (_, schedule) => NasabahCard(
                              child: Column(children: [
                                AppDetailRow(
                                    label: 'Kegiatan',
                                    value: switch (schedule.jenisKegiatan) {
                                      'penimbangan' => 'Penimbangan Sampah',
                                      'pencairan' => 'Pencairan Saldo',
                                      _ => schedule.jenisKegiatan,
                                    }),
                                AppDetailRow(
                                    label: 'Tanggal',
                                    value: nasabahDate(schedule.mulaiPada)),
                                AppDetailRow(
                                    label: 'Mulai',
                                    value: DateFormat('HH:mm')
                                        .format(schedule.mulaiPada.toLocal())),
                                AppDetailRow(
                                    label: 'Selesai',
                                    value: DateFormat('HH:mm').format(
                                        schedule.selesaiPada.toLocal())),
                                AppDetailRow(
                                    label: 'Lokasi', value: schedule.lokasi),
                                if (schedule.keterangan.trim().isNotEmpty)
                                  AppDetailRow(
                                      label: 'Keterangan',
                                      value: schedule.keterangan),
                              ]),
                            ),
                          ),
                        ],
                      )),
            ),
    );
  }
}
