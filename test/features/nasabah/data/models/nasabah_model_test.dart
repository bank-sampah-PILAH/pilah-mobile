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
    expect(payload['tanggal_lahir'], '1990-01-01');
  });

  group('tanggal_lahir is optional (PIL-478)', () {
    NasabahRequest request(String tanggalLahir) => NasabahRequest(
          kode: 'NAS-0001',
          nama: 'Budi Santoso',
          email: 'budi@example.com',
          jenisKelamin: 'Laki-laki',
          tanggalLahir: tanggalLahir,
          noHp: '+6281234567890',
          alamat: 'Jl. Anggrek No. 3',
        );

    test('an empty date is sent as null, not as an empty string', () {
      // '' is not a date: the API answers with a format error, which would
      // make an optional field look broken. null is how "not given" is said.
      final payload = NasabahModel.toPayload(request(''));

      expect(payload.containsKey('tanggal_lahir'), isTrue);
      expect(payload['tanggal_lahir'], isNull);
    });

    test('whitespace alone counts as not given', () {
      expect(NasabahModel.toPayload(request('   '))['tanggal_lahir'], isNull);
    });

    test('the key stays in the body, so clearing a date is a change', () {
      // Omitting it would read as "leave it alone" on an update and a date
      // already on record would survive a pengurus removing it.
      final payload = NasabahModel.toPayload(request(''));

      expect(payload.keys, contains('tanggal_lahir'));
    });

    test('a date that was given still goes out as ISO', () {
      expect(
        NasabahModel.toPayload(request('01/01/1990'))['tanggal_lahir'],
        '1990-01-01',
      );
    });
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
