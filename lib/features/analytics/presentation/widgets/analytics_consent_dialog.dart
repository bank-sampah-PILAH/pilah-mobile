import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';

/// Asks a pengurus whether the steps they take in the app may be noted.
///
/// Answers `true` for agree and `false` for decline. The dialog cannot be
/// dismissed by tapping outside or going back, so there is no answer until the
/// pengurus gives one, and silence is never taken for a refusal or a consent.
///
/// The text says whether the screen is recorded. Where it is, it says personal
/// data (names, balances, address, photos, email addresses, phone numbers) is
/// masked and that the fixed labels of the app (titles, field captions, button
/// labels) stay visible, because `RevealInReplay` leaves them readable. In both
/// cases it says that none of that personal data is noted. It also names who
/// receives the data (PostHog, abroad) and what the browser library sends
/// along: device and browser type, and a location estimated from the IP
/// address. The route of the page is held back by the client's property
/// denylist. With the web recording, the site's origin and the addresses of its
/// static files are part of the recorded page structure, and the text says so.
/// That stays true only while events follow the rules in `docs/ANALYTICS.md`
/// and the client keeps that denylist; change the text together with either.
Future<bool?> showAnalyticsConsentDialog(
  BuildContext context, {
  bool recordsScreen = false,
}) {
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
                'saat setoran disimpan, untuk memahami di mana pengguna '
                'kesulitan dan meningkatkan pengalaman Anda. '
                '${recordsScreen ? _screenRecorded : _screenNotRecorded}\n\n'
                'Data dikirim ke PostHog, penyedia layanan analitik di luar '
                'negeri, bersama data teknis seperti jenis perangkat dan '
                'peramban serta perkiraan lokasi dari alamat IP. '
                '${recordsScreen ? _addressRecorded : _addressNotSent} '
                'PostHog menyimpan data ini untuk kami, '
                'dan tim PILAH yang menganalisisnya.\n\n'
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

const _screenNotRecorded = 'Kami tidak merekam layar, dan tidak mencatat nama '
    'nasabah, saldo, foto, email, atau nomor telepon.';

const _addressNotSent = 'Alamat halaman tidak dikirim.';

// The recording holds a picture of the page structure, which names the site and
// its files, so the text does not promise more than is true.
const _addressRecorded = 'Rute halaman tidak dikirim, tetapi alamat situs dan '
    'berkas bawaannya ikut tercatat sebagai bagian dari tampilan halaman.';

// What is masked and what is not is spelled out: a pengurus must be able to tell
// what someone watching the recording can read.
const _screenRecorded = 'Kami juga merekam layar, supaya tim dapat melihat '
    'langkah mana yang menyulitkan. Nama nasabah, saldo, alamat, foto, email, '
    'dan nomor telepon disamarkan sehingga tidak terlihat. Label dan judul '
    'tetap dari aplikasi tetap terlihat.';
