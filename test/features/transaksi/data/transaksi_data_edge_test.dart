import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';

class _MockNetworkService extends Mock implements NetworkService {}

class _MockSource extends Mock implements TransaksiRemoteDataSource {}

class _FakeFilter extends Fake implements TransaksiFilter {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeFilter());
    registerFallbackValue(TransaksiEditRequest(id: 'x', alasan: 'x'));
  });

  test('export accepts a byte payload delivered as a plain int list', () async {
    final network = _MockNetworkService();
    when(() => network.getBytes('/api/v1/transaksi/export',
            queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async => Response<List<int>>(
              requestOptions: RequestOptions(path: '/export'),
              data: [4, 5, 6],
            ));

    final export = await TransaksiRemoteDataSourceImpl(network)
        .exportTransaksi(const TransaksiFilter());

    expect(export.bytes, Uint8List.fromList([4, 5, 6]));
  });

  test('the repository maps a non-Dio exception from the export source',
      () async {
    final source = _MockSource();
    when(() => source.exportTransaksi(any()))
        .thenThrow(const FormatException('x'));

    final result = await TransaksiRepositoryImpl(source)
        .exportTransaksi(const TransaksiFilter());

    expect(result.fold((l) => l, (r) => null), isA<GeneralException>());
  });

  test('copyWith keeps the WA status unless told otherwise', () {
    final entity = TransaksiEntity(
      initials: 'AB',
      avatarColor: Colors.red,
      textColor: Colors.white,
      name: 'Ab',
      subtitle: '',
      amount: '',
      isWaSuccess: true,
      balance: '',
      items: const [],
    );

    expect(entity.copyWith().isWaSuccess, isTrue);
    expect(entity.copyWith(isWaSuccess: false).isWaSuccess, isFalse);
  });

  test('the "semua" filter sends only the period', () {
    final filter = TransaksiFilter.semua(pageSize: int.parse('5'));

    expect(filter.toQueryParams(), {'periode': 'semua'});
    expect(filter.pageSize, 5);
  });

  test('editing PATCHes only what changed and maps the revisions back',
      () async {
    final network = _MockNetworkService();
    when(() => network.patch('/api/v1/transaksi/t1', data: any(named: 'data')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/t1'),
              data: {
                'nasabah_nama': 'Budi',
                'total_nilai': '6000',
                'saldo_setelah_transaksi': '6000',
                'status_wa': 'belum_dikirim',
                'catatan': 'ok',
                'items': [
                  {
                    'jenis_sampah_id': 'j1',
                    'nama_sampah_snapshot': 'Botol',
                    'berat': '3.000',
                    'harga_snapshot': '2000',
                    'subtotal': '6000',
                  },
                ],
                'harga_pada_tanggal': {'j1': '2000.00', 'j2': '800'},
                'revisi': [
                  {
                    'versi': 1,
                    'total_nilai': '4000',
                    'catatan': '',
                    'alasan': 'Salah timbang',
                    'diubah_oleh_nama': 'Ibu Sari',
                    'diubah_pada': 'bukan tanggal',
                    'items': [
                      {
                        'nama_sampah': 'Botol',
                        'harga': '2000',
                        'berat': '2.000',
                        'subtotal': '4000',
                      },
                    ],
                  },
                ],
              },
            ));

    final detail = await TransaksiRemoteDataSourceImpl(network).editTransaksi(
      TransaksiEditRequest(
        id: 't1',
        items: [ItemSetoranRequest(jenisSampahId: 'j1', berat: 3)],
        alasan: ' Salah timbang ',
      ),
    );

    final sent = verify(() => network.patch('/api/v1/transaksi/t1',
        data: captureAny(named: 'data'))).captured.single as Map;
    expect(sent, {
      'items': [
        {'jenis_sampah_id': 'j1', 'berat': 3.0}
      ],
      'alasan': 'Salah timbang',
    });
    expect(detail.items.single.jenisSampahId, 'j1');
    expect(detail.items.single.beratKg, 3);
    expect(detail.items.single.hargaPerKg, 2000);
    expect(detail.revisi.single.versi, 1);
    expect(detail.revisi.single.alasan, 'Salah timbang');
    expect(detail.revisi.single.diubahPada, isNull);
    expect(detail.catatan, 'ok');
    expect(detail.hargaPadaTanggal, {'j1': 2000, 'j2': 800});
  });

  test('the repository wraps an edit failure as a NetworkException', () async {
    final source = _MockSource();
    when(() => source.editTransaksi(any()))
        .thenAnswer((_) => Future.error(const FormatException('x')));

    final result = await TransaksiRepositoryImpl(source)
        .editTransaksi(TransaksiEditRequest(id: 'x', alasan: 'x'));

    expect(result.fold((l) => l, (r) => null), isA<GeneralException>());
  });
}
