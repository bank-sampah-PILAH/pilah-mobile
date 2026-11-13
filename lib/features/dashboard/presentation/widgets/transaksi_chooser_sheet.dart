import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Transaksi yang bisa dicatat Pengurus dari beranda.
enum TransaksiPilihan {
  setoran,
  pencairan;

  IconData get icon => switch (this) {
        TransaksiPilihan.setoran => Icons.add_circle_outline,
        TransaksiPilihan.pencairan => Icons.payments_outlined,
      };

  String get judul => switch (this) {
        TransaksiPilihan.setoran => 'Catat Setoran',
        TransaksiPilihan.pencairan => 'Pencairan',
      };

  String get keterangan => switch (this) {
        TransaksiPilihan.setoran => 'Rekam setoran sampah dari nasabah',
        TransaksiPilihan.pencairan =>
          'Buat draft, potongan, dan pencairan banyak nasabah',
      };
}

/// Memilih transaksi mana yang akan dicatat sebelum formulirnya dibuka.
///
/// Satu pintu masuk untuk keduanya tanpa menyatukan formulirnya sendiri —
/// bentuk datanya terlalu berbeda (banyak item vs satu nilai) (PIL-282).
///
/// Sheet ini tidak tahu pilihan mana yang sedang dibuka: pemanggilnya yang
/// memberi tahu lewat [tersedia], yang berasal dari daftar aksi yang benar
/// benar dimilikinya. Jadi menutup atau membuka sebuah transaksi adalah satu
/// suntingan di satu tempat, bukan di sini.
class TransaksiChooserSheet extends StatelessWidget {
  const TransaksiChooserSheet({super.key, required this.tersedia});

  /// Pilihan yang bisa ditekan. Pilihan di luar daftar ini tetap digambar,
  /// dalam keadaan mati.
  final Set<TransaksiPilihan> tersedia;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHeader(title: 'Transaksi Baru'),
          for (final pilihan in TransaksiPilihan.values) ...[
            const SizedBox(height: 8),
            _ChoiceTile(
              pilihan: pilihan,
              onTap: tersedia.contains(pilihan)
                  ? () => Navigator.of(context).pop(pilihan)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.pilihan, required this.onTap});

  final TransaksiPilihan pilihan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled ? AppColors.greenLight : AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                pilihan.icon,
                color: enabled ? AppColors.greenDark : AppColors.grey100,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pilihan.judul,
                    style: AppTextStyle.title1.copyWith(
                      color: enabled ? AppColors.black : AppColors.grey100,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pilihan.keterangan,
                    style:
                        AppTextStyle.small.copyWith(color: AppColors.grey100),
                  ),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.chevron_right, color: AppColors.grey200),
          ],
        ),
      ),
    );
  }
}
