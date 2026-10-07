import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';

Map<String, dynamic> _jenisJson({Object? terjadwal}) => {
      'id': 'j-1',
      'kode': 'PLS-001',
      'nama_sampah': 'Plastik PET',
      'kategori': 'plastik',
      'deskripsi': '',
      'satuan': 'kg',
      'harga_per_kg': '3500.00',
      'harga_berlaku_mulai': '2026-10-07T04:00:00Z',
      'harga_terjadwal': terjadwal,
      'is_active': true,
    };

void main() {
  group('HargaModel.fromJson', () {
    test('reads when the current price started', () {
      final harga = HargaModel.fromJson(_jenisJson());

      expect(harga.price, 3500);
      expect(harga.berlakuMulai, DateTime.utc(2026, 10, 7, 4));
      expect(harga.hargaTerjadwal, isNull);
    });

    test('reads the next scheduled price', () {
      final harga = HargaModel.fromJson(_jenisJson(terjadwal: {
        'harga_per_kg': '5000.00',
        'berlaku_mulai': '2026-10-14T17:00:00Z',
      }));

      expect(harga.hargaTerjadwal?.harga, 5000);
      expect(
        harga.hargaTerjadwal?.berlakuMulai,
        DateTime.utc(2026, 10, 14, 17),
      );
    });
  });
}
