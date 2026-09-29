import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pencairan/data/model/responses/pencairan_response.dart';
import 'package:pilah_mobile/features/pencairan/data/model/responses/revisi_pencairan_response.dart';

/// Every key the API sends for a pencairan, with non-default values, so a
/// round trip exercises each field of the generated serializer.
Map<String, dynamic> _pencairanJson() => {
      'id': 'p-1',
      'nasabah_id': 'n-1',
      'nasabah_nama': 'Ahmad Ridwan',
      'bank_sampah_nama': 'Bank Sampah BTH',
      'dicatat_oleh_nama': 'Ibu Sari',
      'tanggal': '2026-09-22T03:15:00Z',
      'nominal': '150000.00',
      'metode': 'transfer',
      'keterangan': 'Ditransfer',
      'status': 'tercatat',
      'saldo_sebelum': '465600.00',
      'saldo_sesudah': '315600.00',
      'diperbarui': true,
      'tanggal_edit_minimum': '2026-09-15T03:15:00Z',
    };

Map<String, dynamic> _revisiJson() => {
      'versi': 1,
      'tanggal': '2026-09-22T03:15:00Z',
      'nominal': '200000.00',
      'metode': 'tunai',
      'keterangan': 'Diambil pagi',
      'saldo_sebelum': '465600.00',
      'saldo_sesudah': '265600.00',
      'alasan': 'Salah ketik nominal',
      'diubah_oleh_nama': 'Ibu Sari',
      'diubah_pada': '2026-09-22T05:00:00Z',
    };

/// Serialises through `jsonEncode`, which also converts nested responses.
Map<String, dynamic> _roundTrip(Object response) =>
    jsonDecode(jsonEncode(response)) as Map<String, dynamic>;

void main() {
  test('a pencairan serialises back to the API field names and values', () {
    final json = _pencairanJson();

    expect(_roundTrip(PencairanResponse.fromJson(json)), json);
  });

  test('a revision serialises back to the API field names and values', () {
    final json = _revisiJson();

    expect(_roundTrip(RevisiPencairanResponse.fromJson(json)), json);
  });

  test('the revision history serialises its pencairan and every version', () {
    final json = {
      'pencairan': _pencairanJson(),
      'revisi': [_revisiJson(), _revisiJson()..['versi'] = 2],
    };

    expect(_roundTrip(RiwayatRevisiPencairanResponse.fromJson(json)), json);
  });
}
