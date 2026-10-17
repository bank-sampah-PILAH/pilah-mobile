import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart'
    show nasabahDate;
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';

/// Full announcement content (PIL-244). The row is passed as [extra] from the
/// list — an announcement that expired or was withdrawn can no longer appear
/// there, so there is no stale content to guard against on this screen.
class PengumumanDetailPage extends StatelessWidget {
  const PengumumanDetailPage({super.key, required this.pengumuman});

  static const route = '/pengumuman/detail';

  final PengumumanEntity pengumuman;

  @override
  Widget build(BuildContext context) {
    final terbitPada = pengumuman.terbitPada;
    final bankMention = [
      if (pengumuman.bankSampahNama.isNotEmpty) pengumuman.bankSampahNama,
      if (pengumuman.bankSampahKota.isNotEmpty) pengumuman.bankSampahKota,
      if (pengumuman.bankSampahAlamat.isNotEmpty) pengumuman.bankSampahAlamat,
    ].join(' · ');
    return Scaffold(
      backgroundColor: NasabahStyle.background,
      appBar: const NasabahPageAppBar(
        title: 'Detail Pengumuman',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              pengumuman.judul,
              style:
                  NasabahStyle.text(20, weight: FontWeight.w700, height: 1.3),
            ),
            if (terbitPada != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 14, color: NasabahStyle.muted),
                  const SizedBox(width: 6),
                  Text(
                    nasabahDate(terbitPada),
                    style: NasabahStyle.text(12, color: NasabahStyle.muted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: NasabahStyle.line, height: 1),
            const SizedBox(height: 16),
            if (bankMention.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.store_outlined,
                      size: 16, color: NasabahStyle.emerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bankMention,
                      style: NasabahStyle.text(13,
                          weight: FontWeight.w500, height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text(
              pengumuman.isi,
              style: NasabahStyle.text(14, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}
