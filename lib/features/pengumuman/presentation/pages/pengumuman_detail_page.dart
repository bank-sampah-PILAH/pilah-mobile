import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
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
    return Scaffold(
      backgroundColor: NasabahStyle.background,
      appBar: const NasabahPageAppBar(title: 'Pengumuman'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NasabahCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pengumuman.judul,
                      style: NasabahStyle.text(18, weight: FontWeight.w700),
                    ),
                    if (terbitPada != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        nasabahDate(terbitPada),
                        style: NasabahStyle.text(12, color: NasabahStyle.muted),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      pengumuman.isi,
                      style: NasabahStyle.text(14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
