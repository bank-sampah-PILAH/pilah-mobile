/// Sample data for the WhatsApp template live preview shown in "Pengaturan
/// Umum".
///
/// The rendering itself is not done here. It lives in [renderWaTemplate], which
/// the transaksi success flow also uses to build the message it actually sends —
/// this file only supplies the dummy setoran the preview renders against. That
/// split is the point: a pengelola edits their template against this preview, so
/// the preview has to resolve variables exactly as the real message will.
///
/// Two item-list variables are supported and intentionally differ:
///   * `{daftar_item}`       — item name and weight only.
///   * `{daftar_item_harga}` — name, weight, price per kg, and subtotal.
library;

import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';

export 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart'
    show buildDaftarItem, buildDaftarItemHarga, formatRupiahId;

/// The preview's deposit line. An alias rather than a separate type: the preview
/// feeds the same renderer as the real message, so it needs the same shape.
typedef WaPreviewItem = WaTemplateItem;

/// Sample deposit used for the preview. The subtotals sum to Rp 15.600, which is
/// the same figure `{Total}` previews as, so the sample message stays internally
/// consistent.
const List<WaPreviewItem> kWaPreviewItems = [
  WaPreviewItem(namaSampah: 'Plastik PET', berat: 5.2, hargaPerKg: 2500),
  WaPreviewItem(namaSampah: 'Kertas Kardus', berat: 2.0, hargaPerKg: 1300),
];

/// Renders a raw template into the sample message shown in "PREVIEW PESAN".
///
/// This is preview-only dummy data; the raw template (with `{...}` variables) is
/// what gets saved.
String renderWaPreview(String template, {DateTime? now}) {
  return renderWaTemplate(
    template,
    nama: 'Budi Santoso',
    items: kWaPreviewItems,
    total: 15600,
    saldo: 125000,
    tanggal: now ?? DateTime.now(),
  );
}
