import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';

void main() {
  group('HargaModel.fromJson', () {
    Map<String, dynamic> json(String hargaPerKg) => {
          'id': 'jenis-1',
          'kode': 'PLS-001',
          'nama_sampah': 'Plastik PET',
          'harga_per_kg': hargaPerKg,
          'kategori': 'plastik',
        };

    test('shows the price with a dot as thousands separator', () {
      expect(HargaModel.fromJson(json('3500.00')).priceFormatted, 'Rp 3.500');
      expect(HargaModel.fromJson(json('12500')).priceFormatted, 'Rp 12.500');
    });

    test('keeps small prices as they are', () {
      expect(HargaModel.fromJson(json('500.00')).priceFormatted, 'Rp 500');
    });
  });
}
