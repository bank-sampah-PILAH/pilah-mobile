/// Builds the `wa.me` deep link opened by "Kirim Notif WhatsApp & Selesai" on
/// the transaction success sheet.
///
/// TEMP (Twilio outage): the notification is normally rendered and dispatched
/// server-side. While that path is unavailable the app hands the pengelola a
/// pre-filled WhatsApp draft instead, so the nasabah still gets the same message
/// — it is sent from the pengelola's own number rather than the business one.
/// The backend is reduced to storing the template string; the rendering that
/// used to happen there now happens here.
///
/// The template comes from the editor in "Pengaturan Umum" and is resolved by
/// the shared [renderWaTemplate], the same renderer that drives that screen's
/// live preview — so what a pengelola previews is what their nasabah receives.
///
/// String building lives here rather than in the page so it can be unit-tested
/// without pumping a widget.
library;

import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';

export 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart'
    show WaTemplateItem;

/// A single deposit line rendered into the notification message.
typedef WaSetoranItem = WaTemplateItem;

/// The message sent when a bank sampah has not written a template of its own.
///
/// Expressed in the same variable language as a custom template so both take one
/// code path, and worded to match the fixed message previously registered with
/// Twilio — a pengelola who never opens the editor sees no change.
const String kDefaultWaTemplate = 'Halo {Nama} 👋\n'
    'Setoran sampahmu sudah berhasil kami catat! '
    'Berikut adalah rincian setoran sampah hari ini:\n'
    '{daftar_item}\n'
    'Terima kasih atas kontribusimu untuk lingkungan yang lebih bersih 🌱';

/// Normalizes an Indonesian phone number to the digits-only, country-coded form
/// `wa.me` expects (`6281234567890`).
///
/// Everything that is not a digit is dropped first — spaces, dashes, dots,
/// brackets and the leading `+` — so a display-formatted number like
/// `+62 812-3456-7890` normalizes the same as a raw one. The remaining digits
/// are then resolved to a country-coded number:
///
///   * `0812…`  → `62812…`  (national trunk `0` swapped for the country code)
///   * `62812…` → unchanged
///   * `812…`   → `62812…`  (bare national number, no prefix)
///   * `620812…` → `62812…`
///
/// That last case is not hypothetical: the nasabah forms save `'+62' + <typed
/// digits>`, so a user who types their number *with* the leading `0` is stored
/// with both prefixes. Indonesian numbers never have a `0` directly after the
/// country code, so collapsing it is unambiguous.
///
/// Returns an empty string when [raw] holds no digits at all. Callers may still
/// build a link with it — `wa.me` without a number opens WhatsApp's contact
/// picker with the message pre-filled, which is a better outcome than an error.
String normalizeWaPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('620')) return '62${digits.substring(3)}';
  if (digits.startsWith('62')) return digits;
  if (digits.startsWith('0')) return '62${digits.substring(1)}';
  return '62$digits';
}

/// Builds the notification body for a completed setoran.
///
/// [customTemplate] is the bank sampah's saved template. When it is null or
/// blank — never configured, or deliberately cleared — [kDefaultWaTemplate] is
/// used instead, so the message is never empty and the nasabah never receives a
/// bare `{variable}` token.
///
/// [total] and [saldo] are the backend-authoritative figures from the created
/// transaction, and are only read if the template mentions `{Total}`/`{Saldo}`.
/// [tanggal] defaults to now, which is when the setoran was recorded.
String buildWaSetoranMessage({
  required String nama,
  required List<WaSetoranItem> items,
  String? customTemplate,
  int total = 0,
  int saldo = 0,
  DateTime? tanggal,
}) {
  final template = (customTemplate == null || customTemplate.trim().isEmpty)
      ? kDefaultWaTemplate
      : customTemplate;

  return renderWaTemplate(
    template,
    nama: nama,
    items: items,
    total: total,
    saldo: saldo,
    tanggal: tanggal ?? DateTime.now(),
  );
}

/// Builds the full `https://wa.me/<nomor>?text=<pesan>` link.
///
/// The message is escaped with [Uri.encodeComponent] rather than handed to
/// [Uri.queryParameters], which encodes spaces as `+` — literal `+` characters
/// are not reliably read back as spaces by WhatsApp. `encodeComponent` emits
/// `%20`, turns the newlines separating the item lines into `%0A`, and
/// percent-encodes the emoji as UTF-8, so the draft arrives with its line breaks
/// and 👋 / 🌱 intact.
Uri buildWaSetoranLink({
  required String phone,
  required String nama,
  required List<WaSetoranItem> items,
  String? customTemplate,
  int total = 0,
  int saldo = 0,
  DateTime? tanggal,
}) {
  final message = buildWaSetoranMessage(
    nama: nama,
    items: items,
    customTemplate: customTemplate,
    total: total,
    saldo: saldo,
    tanggal: tanggal,
  );
  return Uri.parse(
    'https://wa.me/${normalizeWaPhone(phone)}'
    '?text=${Uri.encodeComponent(message)}',
  );
}
