import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/profile/domain/wa_template_preview.dart';

void main() {
  // Weight formatting itself lives in (and is tested by) WeightFormatter; these
  // suites cover how the template preview composes it.
  group('formatRupiahId', () {
    test('groups thousands with dots', () {
      expect(formatRupiahId(1500), '1.500');
      expect(formatRupiahId(3450), '3.450');
      expect(formatRupiahId(125000), '125.000');
      expect(formatRupiahId(750), '750');
    });
  });

  group('buildDaftarItem', () {
    const items = [
      WaPreviewItem(namaSampah: 'kertas hvs', berat: 2.3, hargaPerKg: 1500),
      WaPreviewItem(namaSampah: 'botol', berat: 2.0, hargaPerKg: 1000),
    ];

    test('lists only name and weight', () {
      expect(
        buildDaftarItem(items),
        '- kertas hvs 2,3 kg\n- botol 2 kg',
      );
    });

    test('omits the price and subtotal entirely', () {
      final result = buildDaftarItem(items);
      expect(result, isNot(contains('Rp')));
      expect(result, isNot(contains('x')));
      expect(result, isNot(contains('=')));
    });
  });

  group('buildDaftarItemHarga', () {
    const items = [
      WaPreviewItem(namaSampah: 'kertas hvs', berat: 2.3, hargaPerKg: 1500),
    ];

    test('includes name, weight, price per kg, and subtotal', () {
      expect(
        buildDaftarItemHarga(items),
        '- kertas hvs 2,3 kg x Rp 1.500 = Rp 3.450',
      );
    });

    test('applies the same clean weight formatting', () {
      const whole = [
        WaPreviewItem(namaSampah: 'botol', berat: 2.0, hargaPerKg: 1000),
      ];
      expect(
        buildDaftarItemHarga(whole),
        '- botol 2 kg x Rp 1.000 = Rp 2.000',
      );
    });
  });

  group('renderWaPreview', () {
    test('{daftar_item} resolves to name and weight only', () {
      final rendered = renderWaPreview('{daftar_item}');
      expect(rendered, '- Plastik PET 5,2 kg\n- Kertas Kardus 2 kg');
      expect(rendered, isNot(contains('Rp')));
    });

    test('{daftar_item_harga} resolves to the full calculation', () {
      final rendered = renderWaPreview('{daftar_item_harga}');
      expect(
        rendered,
        '- Plastik PET 5,2 kg x Rp 2.500 = Rp 13.000\n'
        '- Kertas Kardus 2 kg x Rp 1.300 = Rp 2.600',
      );
    });

    test('both variables in one template resolve independently', () {
      final rendered =
          renderWaPreview('{daftar_item}\n---\n{daftar_item_harga}');
      expect(
        rendered,
        '- Plastik PET 5,2 kg\n'
        '- Kertas Kardus 2 kg\n'
        '---\n'
        '- Plastik PET 5,2 kg x Rp 2.500 = Rp 13.000\n'
        '- Kertas Kardus 2 kg x Rp 1.300 = Rp 2.600',
      );
    });

    test('collapses an optional leading "Rp " on currency variables', () {
      expect(renderWaPreview('Rp {Saldo}'), 'Rp 125.000');
      expect(renderWaPreview('Total: Rp {Total}'), 'Total: Rp 15.600');
    });

    test('resolves the remaining scalar variables', () {
      expect(renderWaPreview('{Nama}'), 'Budi Santoso');
      expect(
        renderWaPreview('{Tanggal}', now: DateTime(2026, 7, 24)),
        '24 Juli 2026',
      );
    });
  });
}
