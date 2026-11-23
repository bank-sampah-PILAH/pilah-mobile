import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

const _path = '/api/v1/transaksi/t1/batalkan';

Map<String, dynamic> _dibatalkan() => {
      'nasabah_nama': 'Budi',
      'tanggal': '2026-10-05T03:00:00Z',
      'total_nilai': '6000.00',
      'saldo_setelah_transaksi': '0',
      'status_wa': 'terkirim',
      'catatan': '',
      'items': [],
      'revisi': [],
      'harga_pada_tanggal': {},
      'status': 'dibatalkan',
      'alasan_batal': 'Dobel',
      'dibatalkan_oleh': 'u1',
      'dibatalkan_oleh_nama': 'Pengelola',
      'dibatalkan_pada': '2026-10-06T02:30:00Z',
    };

void main() {
  late StubApi api;
  setUp(() => api = StubApi());

  test('voiding posts the trimmed alasan and returns the voided detail',
      () async {
    api.on('POST', _path, json: _dibatalkan());

    final result = await buildTransaksiNotifier(api)
        .batalkanTransaksi(TransaksiBatalRequest(id: 't1', alasan: ' Dobel '));

    expect(api.last.method, 'POST');
    expect(api.last.path, _path);
    expect(api.last.json, {'alasan': 'Dobel'});
    final detail = result.detail!;
    expect(result.error, isNull);
    expect(detail.isDibatalkan, isTrue);
    expect(detail.alasanBatal, 'Dobel');
    expect(detail.dibatalkanOlehNama, 'Pengelola');
    expect(detail.dibatalkanPada, DateTime.utc(2026, 10, 6, 2, 30).toLocal());
  });

  test('a refused void hands back the backend message as written', () async {
    const pesan =
        'Setoran ini tidak bisa dibatalkan karena sebagian saldonya sudah dicairkan';
    api.on('POST', _path, status: 409, json: {'error': pesan});

    final result = await buildTransaksiNotifier(api)
        .batalkanTransaksi(TransaksiBatalRequest(id: 't1', alasan: 'Dobel'));

    expect(result.detail, isNull);
    expect(result.error, pesan);
  });

  test('a tercatat detail is not voided', () async {
    api.on('GET', '/api/v1/transaksi/t1',
        json: {..._dibatalkan(), 'status': 'tercatat', 'alasan_batal': ''});

    final detail = await buildTransaksiNotifier(api).fetchTransaksiDetail('t1');

    expect(detail!.isDibatalkan, isFalse);
  });
}
