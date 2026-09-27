import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

void main() {
  test('toPayload includes email', () {
    final payload = NasabahModel.toPayload(
      NasabahRequest(
        kode: 'NAS-0001',
        nama: 'Budi Santoso',
        email: 'budi@example.com',
        jenisKelamin: 'Laki-laki',
        tanggalLahir: '01/01/1990',
        noHp: '+6281234567890',
        alamat: 'Jl. Anggrek No. 3',
      ),
    );

    expect(payload['email'], 'budi@example.com');
    expect(payload['kode'], 'NAS-0001');
  });

  test('fromJson parses email', () {
    final model = NasabahModel.fromJson({
      'id': 'abc',
      'kode': 'NAS-0001',
      'nama': 'Budi Santoso',
      'email': 'budi@example.com',
      'no_hp': '081234567890',
      'total_saldo': 0,
      'is_active': true,
      'alamat': 'Jl. Anggrek No. 3',
      'jenis_kelamin': 'laki-laki',
      'tanggal_lahir': '1990-01-01',
      'tanggal_daftar': '2026-09-19',
    });

    expect(model.email, 'budi@example.com');
  });

  test('fromJson tolerates missing email', () {
    final model = NasabahModel.fromJson({
      'id': 'abc',
      'kode': 'NAS-0001',
      'nama': 'Budi Santoso',
    });

    expect(model.email, '');
  });
}
