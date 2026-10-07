import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart';

class _Network extends Mock implements NetworkService {}

void main() {
  late _Network network;
  late RiwayatRemoteDataSourceImpl source;

  setUp(() {
    network = _Network();
    source = RiwayatRemoteDataSourceImpl(network);
  });

  void respond(String path, Map<String, dynamic> data,
      {Map<String, Object> query = const {}}) {
    when(() => network.get(path, queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async =>
            Response(data: data, requestOptions: RequestOptions(path: path)));
  }

  test('history maps the page contract and forwards membership + page',
      () async {
    respond('/api/v1/nasabah/me/riwayat', {
      'results': [
        {
          'id': 't',
          'tanggal': '2026-09-23T09:00:00Z',
          'tipe': 'setoran',
          'total_nilai': '5000.00'
        },
      ],
      'next': 'https://untrusted.example/page=3',
      'count': 50
    });

    final history = await source.history('member-b', page: 2);

    expect(history.hasNext, isTrue);
    expect(history.activities.single.amount, '5000.00');
    verify(() => network.get('/api/v1/nasabah/me/riwayat',
        queryParams: {'keanggotaan_id': 'member-b', 'page': 2})).called(1);
  });

  test('a page without next ends the paging', () async {
    respond('/api/v1/nasabah/me/riwayat', {'results': [], 'count': 0});

    expect((await source.history('member-b')).hasNext, isFalse);
  });

  test('setoran detail is loaded for the selected membership', () async {
    const id = '6b4c70b3-fd54-481b-a0a7-cbe06695fd83';
    const path = '/api/v1/nasabah/me/riwayat/$id';
    respond(path, {
      'id': id,
      'tanggal': '2026-09-23T09:00:00Z',
      'tipe': 'setoran',
      'total_nilai': '5000.00',
      'catatan': 'Setoran rutin',
      'saldo_setelah_transaksi': 15000.0,
      'items': [
        {
          'id': 'item-1',
          'jenis_sampah_id': 'kind-1',
          'nama_sampah_snapshot': 'Plastik PET',
          'harga_snapshot': '5000.00',
          'berat': '1.000',
          'subtotal': '5000.00',
        },
      ],
    });

    final detail = await source.setoranDetail('member-b', id);

    expect(detail.amount, '5000.00');
    expect(detail.balanceAfter, '15000.00');
    expect(detail.items.single.name, 'Plastik PET');
    expect(detail.items.single.weight, '1.000');
    verify(() => network.get(path, queryParams: {'keanggotaan_id': 'member-b'}))
        .called(1);
  });

  test('detail keeps a decimal-string balance as sent', () async {
    const id = '1a2c70b3-fd54-481b-a0a7-cbe06695fd83';
    respond('/api/v1/nasabah/me/riwayat/$id', {
      'id': id,
      'tanggal': '2026-09-23T09:00:00Z',
      'tipe': 'setoran',
      'total_nilai': '5000.00',
      'saldo_setelah_transaksi': '15000.00',
      'items': [],
    });

    expect((await source.setoranDetail('b', id)).balanceAfter, '15000.00');
  });

  test('exportPdf reads bytes and the header filename', () async {
    when(() => network.getBytes('/api/v1/nasabah/me/riwayat/export-pdf',
        queryParams: any(named: 'queryParams'))).thenAnswer(
      (_) async => Response(
        data: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        requestOptions: RequestOptions(path: '/pdf'),
        headers: Headers.fromMap({
          'content-disposition': [
            'attachment; filename="Riwayat_Aktivitas_NSB-1.pdf"'
          ]
        }),
      ),
    );

    final export = await source.exportPdf('member-b');

    expect(export.bytes, [0x25, 0x50, 0x44, 0x46]);
    expect(export.filename, 'Riwayat_Aktivitas_NSB-1.pdf');
    verify(() => network.getBytes('/api/v1/nasabah/me/riwayat/export-pdf',
        queryParams: {'keanggotaan_id': 'member-b'})).called(1);
  });

  test('a stripped Content-Disposition header falls back to a fixed filename',
      () async {
    when(() => network.getBytes(any(), queryParams: any(named: 'queryParams')))
        .thenAnswer(
      (_) async => Response(
        data: Uint8List.fromList([1]),
        requestOptions: RequestOptions(path: '/pdf'),
      ),
    );

    expect(
        (await source.exportPdf('member-b')).filename, 'Riwayat_Aktivitas.pdf');
  });

  test('a quoted filename is unquoted', () async {
    when(() => network.getBytes(any(), queryParams: any(named: 'queryParams')))
        .thenAnswer(
      (_) async => Response(
        data: Uint8List.fromList([1]),
        requestOptions: RequestOptions(path: '/pdf'),
        headers: Headers.fromMap({
          'content-disposition': [
            'attachment; filename="Riwayat_Aktivitas_X.pdf"'
          ]
        }),
      ),
    );

    expect((await source.exportPdf('member-b')).filename,
        'Riwayat_Aktivitas_X.pdf');
  });

  test('exportPdf treats a list payload as int bytes', () async {
    when(() => network.getBytes(any(), queryParams: any(named: 'queryParams')))
        .thenAnswer(
      (_) async => Response(
        data: [1, 2, 3],
        requestOptions: RequestOptions(path: '/pdf'),
      ),
    );

    expect((await source.exportPdf('member-b')).bytes, [1, 2, 3]);
  });

  test('422 with membership choices raises the picker error', () async {
    when(() => network.get(any(), queryParams: any(named: 'queryParams')))
        .thenThrow(DioException(
            requestOptions: RequestOptions(),
            response: Response(
                requestOptions: RequestOptions(),
                statusCode: 422,
                data: {
                  'errors': {
                    'keanggotaan_id': 'Pilih',
                    'pilihan': [
                      {'id': 'b', 'bank_sampah_nama': 'Mawar'}
                    ]
                  }
                })));

    await expectLater(
        source.history('member-b'),
        throwsA(isA<NasabahApiException>()
            .having((e) => e.choices.single.id, 'choice', 'b')));
  });

  for (final status in [401, 403, 404, 422, 500]) {
    test('HTTP $status becomes a safe actionable error', () async {
      when(() => network.get(any(), queryParams: any(named: 'queryParams')))
          .thenThrow(DioException(
              requestOptions: RequestOptions(),
              response: Response(
                  requestOptions: RequestOptions(),
                  statusCode: status,
                  data: {'error': 'private detail'})));
      await expectLater(
          source.history('member-b'),
          throwsA(isA<NasabahApiException>().having(
              (e) => e.message, 'message', isNot(contains('private detail')))));
    });
  }
}
