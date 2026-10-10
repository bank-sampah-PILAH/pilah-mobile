import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// How a question weighs: green for going ahead, red for throwing something
/// away, amber for a warning.
enum KonfirmasiNada {
  normal(AppColors.greenDark, Color(0xFFE8F5E9)),
  bahaya(Color(0xFFC62828), Color(0xFFFDECEC)),
  peringatan(Color(0xFFB45309), Color(0xFFFEF3C7));

  const KonfirmasiNada(this.warna, this.latar);

  final Color warna;
  final Color latar;
}

/// Asks a yes-or-no question in a white, rounded bottom sheet, like the other
/// sheets of pencairan: an icon in a tinted circle, a title, a line of
/// explanation, optional [isi] of its own, and the two answers side by side.
/// Dismissing the sheet answers no.
Future<bool> showPencairanKonfirmasi(
  BuildContext context, {
  required IconData icon,
  required String judul,
  String? pesan,
  Widget? isi,
  required String ya,
  String tidak = 'Batal',
  KonfirmasiNada nada = KonfirmasiNada.normal,
}) async {
  final hasil = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(color: nada.latar, shape: BoxShape.circle),
                  child: Icon(icon, color: nada.warna, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(judul, style: AppTextStyle.headline3)),
              ],
            ),
            if (pesan != null) ...[
              const SizedBox(height: 12),
              Text(pesan,
                  style: AppTextStyle.small.copyWith(color: Colors.grey[800])),
            ],
            if (isi != null) ...[
              const SizedBox(height: 16),
              isi,
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('konfirmasi-tidak'),
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(tidak),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('konfirmasi-ya'),
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nada.warna,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(ya),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return hasil == true;
}
