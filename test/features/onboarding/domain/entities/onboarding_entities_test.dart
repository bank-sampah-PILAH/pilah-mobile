import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

void main() {
  group('BankSampahDirectoryEntity.fromJson', () {
    test('degrades to blank fields instead of throwing on a null id/nama', () {
      final entity = BankSampahDirectoryEntity.fromJson(const {
        'id': null,
        'nama': null,
        'alamat': 'Jl. Melati',
        'kota': 'Depok',
        'foto_logo': null,
      });

      expect(entity.id, '');
      expect(entity.nama, '');
      expect(entity.alamat, 'Jl. Melati');
    });

    test('reads a fully populated bank sampah normally', () {
      final entity = BankSampahDirectoryEntity.fromJson(const {
        'id': 'bank-1',
        'nama': 'Bank Sampah BTH',
        'alamat': 'Kel. Kukusan',
        'kota': 'Depok',
        'foto_logo': 'https://example.com/logo.png',
      });

      expect(entity.id, 'bank-1');
      expect(entity.nama, 'Bank Sampah BTH');
      expect(entity.fotoLogo, 'https://example.com/logo.png');
    });
  });
}
