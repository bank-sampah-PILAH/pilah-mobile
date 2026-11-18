import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/riwayat_harga_content.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

/// Every price version of one jenis sampah, newest first (PIL-331).
class RiwayatHargaPage extends StatelessWidget {
  static const route = '/riwayat-harga';

  final HargaEntity jenis;

  const RiwayatHargaPage({super.key, required this.jenis});

  @override
  Widget build(BuildContext context) =>
      RiwayatHargaView(jenisId: jenis.id, namaJenis: jenis.name);
}

class RiwayatHargaView extends StatefulWidget {
  final String jenisId;
  final String namaJenis;

  const RiwayatHargaView({
    super.key,
    required this.jenisId,
    required this.namaJenis,
  });

  @override
  State<RiwayatHargaView> createState() => _RiwayatHargaViewState();
}

class _RiwayatHargaViewState extends State<RiwayatHargaView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NasabahPageAppBar(
        title: 'Riwayat Harga',
        subtitle: widget.namaJenis,
        showBack: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: RiwayatHargaContent(jenisId: widget.jenisId),
      ),
    );
  }
}
