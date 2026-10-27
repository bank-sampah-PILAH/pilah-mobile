import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';

void main() {
  test('defaults fields absent from older schedule responses', () {
    final model = JadwalModel.fromJson({
      'id': 'jadwal-1',
      'bank_sampah_id': 'bank-1',
      'jenis_kegiatan': 'penimbangan',
      'mulai_pada': '2026-10-10T01:00:00Z',
      'selesai_pada': '2026-10-10T03:00:00Z',
      'lokasi': 'Balai Warga',
    });

    expect(model.keterangan, '');
    expect(model.cakupanPenerima, 'semua_nasabah');
    expect(model.penerimaIds, isEmpty);
    expect(model.status, 'draft');
    expect(model.isOverlapping, isFalse);
  });

  test('schedule entity exposes lifecycle status checks', () {
    expect(_withStatus('draft').isPublished, isFalse);
    expect(_withStatus('diterbitkan').isPublished, isTrue);
    expect(_withStatus('dibatalkan').isCancelled, isTrue);
    expect(_withStatus('selesai').isCompleted, isTrue);
  });

  test('schedule model maps the public API contract in both directions', () {
    final model = JadwalModel.fromJson({
      'id': 'jadwal-1',
      'bank_sampah_id': 'bank-1',
      'jenis_kegiatan': 'penimbangan',
      'mulai_pada': '2026-10-10T01:00:00Z',
      'selesai_pada': '2026-10-10T03:00:00Z',
      'lokasi': 'Balai Warga RW 04',
      'keterangan': 'Bawa sampah terpilah',
      'cakupan_penerima': 'semua_nasabah',
      'penerima_ids': <String>[],
      'status': 'draft',
      'peringatan_jadwal_bertumpuk': true,
    });

    expect(model.id, 'jadwal-1');
    expect(model.isOverlapping, isTrue);
    expect(model.status, 'draft');
    expect(model.toJson(), {
      'jenis_kegiatan': 'penimbangan',
      'mulai_pada': '2026-10-10T01:00:00.000Z',
      'selesai_pada': '2026-10-10T03:00:00.000Z',
      'lokasi': 'Balai Warga RW 04',
      'keterangan': 'Bawa sampah terpilah',
      'cakupan_penerima': 'semua_nasabah',
      'penerima_ids': <String>[],
    });
  });
}

JadwalModel _withStatus(String status) => JadwalModel.fromJson({
      'id': 'jadwal-1',
      'bank_sampah_id': 'bank-1',
      'jenis_kegiatan': 'penimbangan',
      'mulai_pada': '2026-10-10T01:00:00Z',
      'selesai_pada': '2026-10-10T03:00:00Z',
      'lokasi': 'Balai Warga',
      'status': status,
    });
