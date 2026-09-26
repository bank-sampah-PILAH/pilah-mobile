import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/mapper/auth_mapper.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/responses/auth_response.dart';

void main() {
  group('mapResponseToDomain', () {
    test('carries the saved profile fields for complete_profile prefill', () {
      const response = AuthResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: UserResponse(
          id: 'u-1',
          nama: 'Nasabah PILAH',
          email: 'nasabah@example.com',
          role: 'nasabah',
          noHp: '81234567890',
          jenisKelamin: 'perempuan',
          tanggalLahir: '1998-05-20',
          alamat: 'Jl. Melati No. 5',
        ),
      );

      final entity = AuthMapper.mapResponseToDomain(response);

      expect(entity.noHp, '81234567890');
      expect(entity.jenisKelamin, 'perempuan');
      expect(entity.tanggalLahir, '1998-05-20');
      expect(entity.alamat, 'Jl. Melati No. 5');
    });

    test('defaults the profile fields to blank when the backend omits them',
        () {
      const response = AuthResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: UserResponse(
            id: 'u-1', email: 'nasabah@example.com', role: 'nasabah'),
      );

      final entity = AuthMapper.mapResponseToDomain(response);

      expect(entity.noHp, '');
      expect(entity.jenisKelamin, '');
      expect(entity.tanggalLahir, isNull);
      expect(entity.alamat, '');
    });
  });

  group('mapMeResponseToDomain', () {
    test('carries the saved profile fields from the GET /auth/me payload', () {
      final entity = AuthMapper.mapMeResponseToDomain({
        'id': 'u-1',
        'nama': 'Nasabah PILAH',
        'email': 'nasabah@example.com',
        'role': 'nasabah',
        'no_hp': '81234567890',
        'jenis_kelamin': 'perempuan',
        'tanggal_lahir': '1998-05-20',
        'alamat': 'Jl. Melati No. 5',
      });

      expect(entity.noHp, '81234567890');
      expect(entity.jenisKelamin, 'perempuan');
      expect(entity.tanggalLahir, '1998-05-20');
      expect(entity.alamat, 'Jl. Melati No. 5');
    });
  });
}
