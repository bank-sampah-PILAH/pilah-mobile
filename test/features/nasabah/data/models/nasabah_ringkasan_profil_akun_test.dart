import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';

Map<String, dynamic> _detailJson({
  Map<String, dynamic>? profilAkun,
  List<String> profilBerbeda = const [],
}) =>
    {
      'ringkasan_transaksi': {
        'jumlah_transaksi': 2,
        'total_kg': '3.50',
        'tanggal_transaksi_terakhir': '2026-05-12',
      },
      'profil_akun': profilAkun,
      'profil_berbeda': profilBerbeda,
    };

void main() {
  group('Detail nasabah membawa profil yang diisikan nasabah sendiri', () {
    test('profil akun dan field yang berbeda dibaca dari respons detail', () {
      final ringkasan = NasabahRingkasanMapper.fromJson(_detailJson(
        profilAkun: {
          'nama': 'Budi Santosa',
          'jenis_kelamin': 'laki-laki',
          'tanggal_lahir': '1991-02-03',
          'alamat': 'Jl. Melati No. 99',
          'no_hp': '+628999999999',
        },
        profilBerbeda: ['nama', 'no_hp'],
      ));

      final akun = ringkasan.profilAkun!;
      expect(akun.nama, 'Budi Santosa');
      expect(akun.jenisKelamin, 'Laki-laki');
      expect(akun.tanggalLahir, '03/02/1991');
      expect(akun.alamat, 'Jl. Melati No. 99');
      expect(akun.noHp, '+628999999999');
      expect(ringkasan.profilBerbeda, ['nama', 'no_hp']);
    });

    test('nasabah tanpa akun tidak punya profil akun', () {
      final ringkasan = NasabahRingkasanMapper.fromJson(_detailJson());

      expect(ringkasan.profilAkun, isNull);
      expect(ringkasan.profilBerbeda, isEmpty);
    });

    test('respons lama tanpa field itu tetap terbaca', () {
      final ringkasan = NasabahRingkasanMapper.fromJson({
        'ringkasan_transaksi': {'jumlah_transaksi': 2, 'total_kg': '3.50'},
      });

      expect(ringkasan.jumlahTransaksi, 2);
      expect(ringkasan.profilAkun, isNull);
      expect(ringkasan.profilBerbeda, isEmpty);
    });
  });
}
