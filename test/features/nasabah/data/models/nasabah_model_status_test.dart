import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': '1',
        'kode': 'NAS-0001',
        'nama': 'Budi Santoso',
        'no_hp': '081234567890',
        'total_saldo': '0',
        'is_active': true,
        'alamat': 'Jl. Melati No. 3',
        'jenis_kelamin': 'laki-laki',
      };

  group('NasabahModel status mapping', () {
    test('missing status defaults to approved (legacy payloads)', () {
      final model = NasabahModel.fromJson(baseJson());
      expect(model.status, 'approved');
    });

    test('pending status passes through and labels Menunggu', () {
      final model = NasabahModel.fromJson({...baseJson(), 'status': 'pending'});
      expect(model.status, 'pending');
      expect(model.statusLabel(), 'Menunggu');
    });

    test('rejected status labels Ditolak', () {
      final model =
          NasabahModel.fromJson({...baseJson(), 'status': 'rejected'});
      expect(model.statusLabel(), 'Ditolak');
    });

    test('approved status labels Disetujui', () {
      final model =
          NasabahModel.fromJson({...baseJson(), 'status': 'approved'});
      expect(model.statusLabel(), 'Disetujui');
    });
  });
}