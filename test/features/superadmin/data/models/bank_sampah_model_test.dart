import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/superadmin/data/models/bank_sampah_model.dart';

/// A representative BankSampahApprovalListSerializer row, parameterised on the
/// image field so each test controls exactly what the "wire" carried.
Map<String, dynamic> _json({
  String fotoKey = 'foto_kegiatan',
  dynamic fotoValue = 'https://storage.googleapis.com/pilah/kegiatan/bukti.jpg',
}) =>
    {
      'id': '2bb26f62-9f4e-4b1a-8c3d-7e5a1f0c9d84',
      'nama': 'Bank Sampah BTH',
      'alamat': 'Jl. Melati 3, Kukusan, Depok',
      'kota': 'Depok',
      'no_hp_pic': '+628123456789',
      fotoKey: fotoValue,
      'status': 'pending',
      'created_at': '2026-07-01T10:00:00Z',
      'pengelola_utama': {
        'nama': 'Ibu Sari',
        'email': 'sari@example.com',
        'no_hp': '+628123456789',
      },
    };

void main() {
  group('BankSampahModel.fromJson — foto_kegiatan boundary', () {
    test('a valid absolute URL is preserved byte-for-byte', () {
      const url = 'https://storage.googleapis.com/pilah/kegiatan/bukti-123.jpg';
      final model = BankSampahModel.fromJson(_json(fotoValue: url));

      expect(
        model.fotoKegiatan,
        url,
        reason:
            'if the backend sends a URL, the frontend surfaces it unchanged',
      );
    });

    test('a signed GCS URL with query params survives intact', () {
      const url =
          'https://storage.googleapis.com/pilah/kegiatan/b.jpg?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Expires=3600&X-Goog-Signature=abc123';
      final model = BankSampahModel.fromJson(_json(fotoValue: url));

      expect(model.fotoKegiatan, url,
          reason: 'query strings must not be truncated or dropped');
    });

    test('a relative media path is preserved as-is (no mangling)', () {
      const path = '/media/bank_sampah/kegiatan/bukti.jpg';
      final model = BankSampahModel.fromJson(_json(fotoValue: path));

      expect(model.fotoKegiatan, path);
    });

    // The three ways the field legitimately arrives empty. All map to null so
    // the UI shows its honest "no photo" state — none of these is data loss.
    test('an empty string maps to null', () {
      expect(
          BankSampahModel.fromJson(_json(fotoValue: '')).fotoKegiatan, isNull);
    });

    test('an explicit JSON null maps to null', () {
      expect(BankSampahModel.fromJson(_json(fotoValue: null)).fotoKegiatan,
          isNull);
    });

    test('a missing key maps to null', () {
      final json = _json()..remove('foto_kegiatan');
      expect(BankSampahModel.fromJson(json).fotoKegiatan, isNull);
    });

    // Proves the parser is strict about the key — documents that a backend
    // renaming (foto_kegiatan_url, foto, bukti, image_url) would surface as
    // null, i.e. a key mismatch is detectable here, not silently absorbed.
    test('a differently-named key is NOT read (strict key match)', () {
      for (final wrongKey in [
        'foto_kegiatan_url',
        'foto',
        'bukti',
        'image_url'
      ]) {
        final json = _json(fotoKey: wrongKey);
        json.remove('foto_kegiatan');
        expect(
          BankSampahModel.fromJson(json).fotoKegiatan,
          isNull,
          reason:
              'frontend reads only foto_kegiatan; $wrongKey would read null',
        );
      }
    });

    test('the other fields round-trip so the row is otherwise well-formed', () {
      final model = BankSampahModel.fromJson(_json());
      expect(model.nama, 'Bank Sampah BTH');
      expect(model.kota, 'Depok');
      expect(model.status, 'pending');
      expect(model.pengelolaNama, 'Ibu Sari');
    });
  });
}
