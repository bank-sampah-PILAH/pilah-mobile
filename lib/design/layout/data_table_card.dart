import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';

/// Kartu tabel untuk halaman data di layar lebar (nasabah, harga, riwayat).
///
/// Header halaman, pencarian, dan penyaring tetap di atas; kartu ini mengisi
/// sisa tinggi layar dan **hanya baris di dalamnya yang bergulir**, sehingga
/// scrollbarnya ada di dalam kartu. Paginasi menjadi [footer] di dalam kartu,
/// terpaku di dasarnya, bukan footer halaman yang melayang di bawahnya.
///
/// ```dart
/// DataTableCard(
///   header: DataTableCard.head([Expanded(child: Text('NAMA', style: ...))]),
///   body: ListView.separated(...),
///   footer: WebPaginationBar(...),
/// )
/// ```
///
/// Kartu ini harus diberi tinggi terbatas (di dalam `Expanded`).
class DataTableCard extends StatelessWidget {
  const DataTableCard({
    super.key,
    this.toolbar,
    required this.header,
    required this.body,
    this.footer,
  });

  /// Baris di atas kepala kolom, misalnya ringkasan satu garis. Opsional.
  final Widget? toolbar;

  /// Kepala kolom; bentuk [head].
  final Widget header;

  /// Area gulir (`ListView`), diberi sisa tinggi kartu.
  final Widget body;

  /// Kontrol paginasi di dasar kartu. Opsional.
  final Widget? footer;

  /// Baris kepala kolom: latar `AppColors.fill`, jarak samping `xl`, dan sel
  /// ([Expanded] per kolom) yang disusun pemanggil.
  static Widget head(List<Widget> cells, {Key? key}) => Container(
        key: key,
        color: AppColors.fill,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 14,
        ),
        child: Row(children: cells),
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          children: [
            if (toolbar != null) ...[
              toolbar!,
              const Divider(height: 1, color: AppColors.border),
            ],
            header,
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: body),
            if (footer != null) DataTableCardFooter(child: footer!),
          ],
        ),
      ),
    );
  }
}

/// Dasar kartu tabel: garis pemisah dan jarak untuk kontrol paginasi.
class DataTableCardFooter extends StatelessWidget {
  const DataTableCardFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ],
      );
}
