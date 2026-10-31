import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/aktivitas_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';

class MockNetwork extends Mock implements NetworkService {}

void main() {
  late MockNetwork network;
  setUp(() => network = MockNetwork());

  test('sends period, type and page and maps the mixed backend envelope',
      () async {
    final params = <String, dynamic>{
      'periode': 'custom',
      'tipe': 'semua',
      'search': 'Ani',
      'dari_tanggal': '2026-09-01',
      'sampai_tanggal': '2026-09-30',
      'page': 2,
      'page_size': 20,
    };
    when(() => network.get('/api/v1/aktivitas', queryParams: params))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/v1/aktivitas'),
              data: {
                'count': 51,
                'next': '/api/v1/aktivitas?page=3',
                'summary': {
                  'jumlah_transaksi': 0,
                  'total_berat': '0.00',
                  'total_setoran': 0,
                  'total_pencairan': 0,
                  'saldo': 0
                },
                'results': [
                  {
                    'tipe': 'setoran',
                    'data': {
                      'id': 'setoran-1',
                      'nasabah_nama': 'Ani',
                      'tanggal': '2026-09-03T08:00:00+07:00',
                      'total_nilai': '5000.00',
                      'total_berat_kg': '1.5',
                    }
                  },
                  {
                    'tipe': 'pencairan',
                    'data': {
                      'id': 'pencairan-1',
                      'nasabah_nama': 'Ani',
                      'tanggal': '2026-09-02T08:00:00+07:00',
                      'nominal': '1000.00',
                      'metode': 'tunai',
                      'saldo_sebelum': '5000.00',
                      'saldo_sesudah': '4000.00',
                      'diperbarui': true,
                    }
                  },
                ]
              },
            ));
    final result =
        await AktivitasRepositoryImpl(network).history(TransaksiFilter(
      periode: 'custom',
      tipe: 'semua',
      search: ' Ani ',
      dariTanggal: DateTime(2026, 9, 1),
      sampaiTanggal: DateTime(2026, 9, 30),
      page: 2,
    ));
    result.fold((error) => fail(error.toString()), (page) {
      expect(page.hasNext, isTrue);
      expect(page.totalCount, 51);
      expect(page.items.map((item) => item.tipe),
          [ActivitasTipe.setoran, ActivitasTipe.pencairan]);
      expect(page.items.first.transaksi!.id, 'setoran-1');
      expect(page.items.last.pencairan!.diperbarui, isTrue);
    });
    verify(() => network.get('/api/v1/aktivitas', queryParams: params))
        .called(1);
  });

  test('empty final page stops pagination', () async {
    when(() => network.get('/api/v1/aktivitas', queryParams: {
          'periode': 'semua',
          'page': 1,
          'page_size': 20,
        })).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/aktivitas'),
          data: {
            'results': [],
            'next': null,
            'summary': {
              'jumlah_transaksi': 0,
              'total_berat': '0.00',
              'total_setoran': 0,
              'total_pencairan': 0,
              'saldo': 0
            },
          },
        ));
    final result = await AktivitasRepositoryImpl(network)
        .history(const TransaksiFilter.semua());
    result.fold((error) => fail(error.toString()), (page) {
      expect(page.items, isEmpty);
      expect(page.hasNext, isFalse);
    });
  });

  test('network failure returns a typed failure instead of throwing', () async {
    when(() => network.get('/api/v1/aktivitas', queryParams: {
          'periode': 'semua',
          'page': 1,
          'page_size': 20,
        })).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/api/v1/aktivitas'),
      type: DioExceptionType.connectionTimeout,
    ));
    final result = await AktivitasRepositoryImpl(network)
        .history(const TransaksiFilter.semua());
    expect(result.isLeft(), isTrue);
  });

  test(
      'a voided setoran stays in the feed, marked Dibatalkan and muted (PIL-428)',
      () async {
    Map<String, dynamic> setoran(String id, String status) => {
          'tipe': 'setoran',
          'data': {
            'id': id,
            'nasabah_nama': 'Ani',
            'tanggal': '2026-09-03T08:00:00+07:00',
            'total_nilai': '5000.00',
            'total_berat_kg': '1.5',
            'status': status,
          }
        };
    when(() => network.get('/api/v1/aktivitas',
            queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/v1/aktivitas'),
              data: {
                'count': 2,
                'next': null,
                'summary': null,
                'results': [
                  setoran('batal', 'dibatalkan'),
                  setoran('tetap', 'tercatat'),
                ],
              },
            ));

    final result = await AktivitasRepositoryImpl(network)
        .history(const TransaksiFilter.semua());

    result.fold((error) => fail(error.toString()), (page) {
      final [batal, tetap] = page.items;
      expect(batal.transaksi!.isDibatalkan, isTrue);
      expect(batal.badge, 'Dibatalkan');
      expect(batal.amountColor, AppColors.grey100);
      expect(tetap.transaksi!.isDibatalkan, isFalse);
      expect(tetap.badge, isNull);
      expect(tetap.amountColor, isNull);
    });
  });
}
