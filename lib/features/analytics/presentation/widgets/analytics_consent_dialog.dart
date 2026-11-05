import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';

/// Asks a pengurus whether their screen may be recorded.
///
/// Answers `true` for agree and `false` for decline. The dialog cannot be
/// dismissed by tapping outside or going back, so there is no answer until the
/// pengurus gives one, and silence is never taken for a refusal or a consent.
///
/// The text promises that sensitive data is covered; that is true only once the
/// masking of PIL-417 is in place, so analytics must stay switched off
/// (`ENABLE_POSTHOG`) until then.
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
            message: 'Kami ingin merekam layar dan gerakan Anda saat memakai '
                'PILAH, untuk memahami cara pengguna memakai aplikasi dan '
                'membantu kami meningkatkan pengalaman Anda. Nama nasabah, '
                'saldo, foto, email, telepon, dan data sensitif lainnya akan '
                'ditutup. Rekaman hanya dilihat tim PILAH.\n\n'
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
