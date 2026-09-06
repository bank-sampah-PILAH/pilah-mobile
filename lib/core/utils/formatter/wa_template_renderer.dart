/// The `{variable}` language a pengelola writes their WhatsApp template in, and
/// the one renderer that resolves it.
///
/// Two callers share this on purpose:
///   * the live preview in "Pengaturan Umum", which renders against sample data;
///   * the transaksi success flow, which renders against the real setoran and
///     hands the result to `wa.me`.
///
/// They must agree. A pengelola edits their template against the preview, so any
/// variable the preview resolves but the real message does not (or resolves
/// differently) means the app showed them something their nasabah never gets.
/// Keeping one renderer makes that divergence impossible rather than merely
/// unlikely.
library;

import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';

/// A single deposit line used to build the item lists.
class WaTemplateItem {
  final String namaSampah;

  /// Weight in kilograms.
  final double berat;

  /// Price per kilogram, in rupiah. Only `{daftar_item_harga}` reads it.
  final int hargaPerKg;

  const WaTemplateItem({
    required this.namaSampah,
    required this.berat,
    this.hargaPerKg = 0,
  });

  int get subtotal => (berat * hargaPerKg).round();
}

/// Every variable the renderer understands, in the order they are offered as
/// chips. `{daftar_item_harga}` is deliberately last — see [renderWaTemplate]
/// for why the order it is *replaced* in differs.
const List<String> kWaTemplateVariables = [
  '{Nama}',
  '{Total}',
  '{Saldo}',
  '{Tanggal}',
  '{daftar_item}',
  '{daftar_item_harga}',
];

/// Formats a rupiah amount with `.` as the thousands separator, matching the
/// backend (`Rp 1.500`). The `Rp` prefix itself lives in the template text.
String formatRupiahId(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}$buf';
}

/// Formats a date the way the message reads it: `24 Juli 2026`.
String formatTanggalId(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Builds the `{daftar_item}` value: one `- <nama> <berat> kg` line per item.
String buildDaftarItem(List<WaTemplateItem> items) {
  return items
      .map((i) => '- ${i.namaSampah} ${WeightFormatter.formatKg(i.berat)} kg')
      .join('\n');
}

/// Builds the `{daftar_item_harga}` value: name, weight, price per kg, and
/// subtotal — `- <nama> <berat> kg x Rp <harga> = Rp <subtotal>`.
String buildDaftarItemHarga(List<WaTemplateItem> items) {
  return items
      .map(
        (i) => '- ${i.namaSampah} ${WeightFormatter.formatKg(i.berat)} kg '
            'x Rp ${formatRupiahId(i.hargaPerKg)} = Rp ${formatRupiahId(i.subtotal)}',
      )
      .join('\n');
}

/// Resolves every variable in [template] against the supplied values.
///
/// The currency variables swallow an optional preceding `Rp `, so a template
/// written as `Rp {Total}` renders as `Rp 15.600` rather than `Rp Rp 15.600` —
/// writing the prefix is the natural instinct, and the chips insert a token that
/// already carries it.
///
/// `{daftar_item_harga}` is replaced before `{daftar_item}` so the shorter token
/// does not partially consume the longer one and leave a stray `_harga`.
String renderWaTemplate(
  String template, {
  required String nama,
  required List<WaTemplateItem> items,
  required int total,
  required int saldo,
  required DateTime tanggal,
}) {
  return template
      .replaceAll(RegExp(r'(?:Rp\s*)?\{Total\}'), 'Rp ${formatRupiahId(total)}')
      .replaceAll(RegExp(r'(?:Rp\s*)?\{Saldo\}'), 'Rp ${formatRupiahId(saldo)}')
      .replaceAll('{Nama}', nama)
      .replaceAll('{Tanggal}', formatTanggalId(tanggal))
      .replaceAll('{daftar_item_harga}', buildDaftarItemHarga(items))
      .replaceAll('{daftar_item}', buildDaftarItem(items));
}
