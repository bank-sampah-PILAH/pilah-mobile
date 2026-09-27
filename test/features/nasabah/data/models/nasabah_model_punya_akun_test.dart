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

  group('NasabahModel status penautan akun (PIL-206)', () {
    test('nasabah yang tertaut ke akun ditandai punya akun', () {
      final model =
          NasabahModel.fromJson({...baseJson(), 'punya_akun': true});

      expect(model.punyaAkun, isTrue);
    });

    test('nasabah yang belum tertaut ditandai tidak punya akun', () {
      final model =
          NasabahModel.fromJson({...baseJson(), 'punya_akun': false});

      expect(model.punyaAkun, isFalse);
    });

    test('payload tanpa field penautan dianggap belum tertaut', () {
      // Payload lama dan respons yang belum membawa field ini tidak boleh
      // membuat profil ikut terkunci; pengurus akan kehilangan kemampuan
      // mengelola nasabah tanpa akun.
      final model = NasabahModel.fromJson(baseJson());

      expect(model.punyaAkun, isFalse);
    });
  });
}
