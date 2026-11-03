import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

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

/// Asks a yes-or-no question: an icon in a tinted circle, a title, a line of
/// explanation, optional [isi] of its own, and the two answers side by side.
/// A bottom sheet on a phone and a centred dialog in a wider window, through
/// [showAdaptiveConfirmation]. Dismissing it answers no.
Future<bool> showPencairanKonfirmasi(
  BuildContext context, {
  required IconData icon,
  required String judul,
  String? pesan,
  Widget? isi,
  required KonfirmasiJawaban jawaban,
  KonfirmasiNada nada = KonfirmasiNada.normal,
}) async {
  final hasil = await showAdaptiveConfirmation<bool>(
    context: context,
    builder: (sheetContext, _) => SafeArea(
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
                style: AppTextStyle.small.copyWith(color: AppColors.inkSoft)),
          ],
          if (isi != null) ...[
            const SizedBox(height: 16),
            isi,
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const Key('konfirmasi-tidak'),
                  label: jawaban.tidak,
                  variant: AppButtonVariant.neutral,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  key: const Key('konfirmasi-ya'),
                  label: jawaban.ya,
                  variant: switch (nada) {
                    KonfirmasiNada.normal => AppButtonVariant.primary,
                    KonfirmasiNada.bahaya => AppButtonVariant.destructive,
                    KonfirmasiNada.peringatan => AppButtonVariant.warning,
                  },
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return hasil == true;
}
