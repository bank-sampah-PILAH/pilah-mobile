import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/data/models/versi_harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';

void main() {
  test('reads a status this app version does not know as sebelumnya', () {
    // A newer backend may add a status; the row must not claim to be the
    // current or a scheduled price.
    final versi = versiHargaFromJson({
      'harga_per_kg': '3500.00',
      'satuan': 'kg',
      'berlaku_mulai': '2026-09-01T03:00:00Z',
      'dibuat_oleh': 'Ibu Sari',
      'status': 'diarsipkan',
    });

    expect(versi.status, StatusVersiHarga.sebelumnya);
  });
}
