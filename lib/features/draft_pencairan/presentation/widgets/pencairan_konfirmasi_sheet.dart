import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// How a question weighs: green for going ahead, red for throwing something
/// away, amber for a warning.
enum KonfirmasiNada {
  normal(AppColors.greenDark, AppColors.greenLight),
  bahaya(AppColors.danger, AppColors.dangerLight),
  peringatan(AppColors.warning, AppColors.warningLight);

  const KonfirmasiNada(this.warna, this.latar);

  final Color warna;
  final Color latar;
}

/// The two answers of a question, as the buttons read.
class KonfirmasiJawaban {
  final String ya;
  final String tidak;

  const KonfirmasiJawaban(this.ya, [this.tidak = 'Batal']);
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
  required KonfirmasiJawaban jawaban,
  KonfirmasiNada nada = KonfirmasiNada.normal,
}) async {
  final hasil = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(jawaban.tidak),
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
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(jawaban.ya),
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
