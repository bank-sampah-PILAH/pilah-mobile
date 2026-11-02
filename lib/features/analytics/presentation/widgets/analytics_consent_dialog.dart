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
/// (`ENABLE_ANALYTICS`) until then.
Future<bool?> showAnalyticsConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AppDialog(
        title: 'Bantu kami memperbaiki PILAH',
        message: 'Kami ingin merekam layar dan gerakan Anda saat memakai '
            'PILAH, untuk melihat di mana pengurus merasa kesulitan. '
            'Nama nasabah, saldo, foto, email, dan nomor telepon akan ditutup. '
            'Rekaman hanya dilihat tim PILAH.\n\n'
            'Anda boleh menolak dan tetap memakai aplikasi seperti biasa, dan '
            'bisa mengubah pilihan kapan saja di Profil.',
        confirmLabel: 'Setuju',
        cancelLabel: 'Tolak',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    ),
  );
}
