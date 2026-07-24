/// Formatting + rendering for the WhatsApp template live preview shown in
/// "Pengaturan Umum".
///
/// The message that is actually delivered is rendered by the backend; this file
/// only powers the on-screen preview so a pengelola can see how their template
/// resolves before saving. It is kept out of the widget so the string logic can
/// be unit-tested on its own.
///
/// Two item-list variables are supported and intentionally differ:
///   * `{daftar_item}`       — item name and weight only.
///   * `{daftar_item_harga}` — name, weight, price per kg, and subtotal.
library;

import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';

/// A single deposit line used to build the preview item lists.
class WaPreviewItem {
  final String namaSampah;

  /// Weight in kilograms.
  final double berat;

  /// Price per kilogram, in rupiah.
  final int hargaPerKg;

  const WaPreviewItem({
    required this.namaSampah,
    required this.berat,
    required this.hargaPerKg,
  });

  int get subtotal => (berat * hargaPerKg).round();
}

/// Sample deposit used for the preview. The subtotals sum to Rp 15.600, which is
/// the same figure `{Total}` previews as, so the sample message stays internally
/// consistent.
const List<WaPreviewItem> kWaPreviewItems = [
  WaPreviewItem(namaSampah: 'Plastik PET', berat: 5.2, hargaPerKg: 2500),
  WaPreviewItem(namaSampah: 'Kertas Kardus', berat: 2.0, hargaPerKg: 1300),
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

/// Builds the `{daftar_item}` value: one `- <nama> <berat> kg` line per item.
String buildDaftarItem(List<WaPreviewItem> items) {
  return items
      .map((i) => '- ${i.namaSampah} ${WeightFormatter.formatKg(i.berat)} kg')
      .join('\n');
}

/// Builds the `{daftar_item_harga}` value: name, weight, price per kg, and
/// subtotal — `- <nama> <berat> kg x Rp <harga> = Rp <subtotal>`.
String buildDaftarItemHarga(List<WaPreviewItem> items) {
  return items
      .map(
        (i) => '- ${i.namaSampah} ${WeightFormatter.formatKg(i.berat)} kg '
            'x Rp ${formatRupiahId(i.hargaPerKg)} = Rp ${formatRupiahId(i.subtotal)}',
      )
      .join('\n');
}

/// Renders a raw template into the sample message shown in "PREVIEW PESAN".
///
/// This is preview-only dummy data; the raw template (with `{...}` variables) is
/// what gets saved. The currency variables collapse an optional preceding "Rp "
/// so a template written as "Rp {Saldo}" previews as "Rp 125.000" rather than
/// "Rp Rp 125.000".
///
/// `{daftar_item_harga}` is replaced before `{daftar_item}` so the shorter token
/// does not partially consume the longer one.
String renderWaPreview(String template, {DateTime? now}) {
  return template
      .replaceAll(RegExp(r'(?:Rp\s*)?\{Total\}'), 'Rp 15.600')
      .replaceAll(RegExp(r'(?:Rp\s*)?\{Saldo\}'), 'Rp 125.000')
      .replaceAll('{Nama}', 'Budi Santoso')
      .replaceAll('{Tanggal}', _previewDate(now ?? DateTime.now()))
      .replaceAll('{daftar_item_harga}', buildDaftarItemHarga(kWaPreviewItems))
      .replaceAll('{daftar_item}', buildDaftarItem(kWaPreviewItems));
}

String _previewDate(DateTime now) {
  const months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}
