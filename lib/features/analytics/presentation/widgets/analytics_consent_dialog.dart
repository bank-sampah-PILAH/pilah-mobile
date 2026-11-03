import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';

/// Asks a pengurus whether the steps they take in the app may be noted.
///
/// Answers `true` for agree and `false` for decline. The dialog cannot be
/// dismissed by tapping outside or going back, so there is no answer until the
/// pengurus gives one, and silence is never taken for a refusal or a consent.
///
/// The text says the screen is not recorded and that no names, balances, photos,
/// email addresses or phone numbers are noted. That stays true only while events
/// follow the rules in `docs/ANALYTICS.md`.
Future<bool?> showAnalyticsConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      // A long paragraph would stretch the dialog across a wide window and make
      // its lines too long to read. The limit has to sit outside the dialog:
      // the Center loosens the window's fixed size so the limit can apply, and
      // on a phone the screen is narrower than the limit and still wins.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppDialog(
            title: 'Bantu kami meningkatkan pengalaman Anda',
            message:
                'Kami mencatat langkah yang Anda lakukan di PILAH, misalnya '
                'saat setoran disimpan atau jadwal dibuat, untuk memahami di '
                'mana pengguna kesulitan dan meningkatkan pengalaman Anda. '
                'Kami tidak merekam layar, dan tidak mencatat nama nasabah, '
                'saldo, foto, email, atau nomor telepon. Data hanya dilihat '
                'tim PILAH.\n\n'
                'Anda boleh menolak dan tetap memakai aplikasi seperti biasa, '
                'dan bisa mengubah pilihan kapan saja di Profil.',
            confirmLabel: 'Setuju',
            cancelLabel: 'Tolak',
            onConfirm: () => Navigator.of(dialogContext).pop(true),
            onCancel: () => Navigator.of(dialogContext).pop(false),
          ),
        ),
      ),
    ),
  );
}
