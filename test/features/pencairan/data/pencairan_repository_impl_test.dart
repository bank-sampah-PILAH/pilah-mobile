import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/pencairan/data/pencairan_repository_impl.dart';
import 'package:pilah_mobile/features/pencairan/data/remote/pencairan_remote_data_sources.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';

class _MockNetworkService extends Mock implements NetworkService {}

Response<dynamic> _ok(String path, Object data) => Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: 200,
    );

Map<String, dynamic> _pencairanJson() => {
      'id': 'p-1',
      'nasabah_id': 'n-1',
      'nasabah_nama': 'Ahmad Ridwan',
      'tanggal': '2026-09-22T03:15:00Z',
      'nominal': '200000.00',
      'metode': 'tunai',
      'keterangan': 'Diambil pagi',
      'status': 'tercatat',
      'saldo_sebelum': '465600.00',
      'saldo_sesudah': '265600.00',
    };

void main() {
  late _MockNetworkService network;
  late PencairanRepositoryImpl repository;

  setUp(() {
    network = _MockNetworkService();
    repository =
        PencairanRepositoryImpl(PencairanRemoteDataSourceImpl(network));
  });

  group('getSaldo', () {
    test('reads the saldo as whole rupiah', () async {
      when(() => network.get('/api/v1/nasabah/n-1/saldo')).thenAnswer(
        (_) async => _ok('/api/v1/nasabah/n-1/saldo', {
          'nasabah_id': 'n-1',
          'total_saldo': '465600.50',
        }),
      );

      final result = await repository.getSaldo('n-1');

      expect(result, const Right<NetworkException, int>(465600));
    });
  });

  group('createPencairan', () {
    test('posts the payout and maps the recorded pencairan', () async {
      Map<String, dynamic>? sent;
      when(() => network.post('/api/v1/pencairan', data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return _ok('/api/v1/pencairan', _pencairanJson());
      });

      final result = await repository.createPencairan(
        PencairanRequest(
          nasabahId: 'n-1',
          nominal: 200000,
          metode: MetodePencairan.tunai,
          tanggal: DateTime.utc(2026, 9, 22, 3, 15),
          keterangan: '  Diambil pagi  ',
        ),
      );

      expect(sent, {
        'nasabah_id': 'n-1',
        'nominal': 200000,
        'metode': 'tunai',
        'tanggal': '2026-09-22T03:15:00.000Z',
        'keterangan': 'Diambil pagi',
      });
      final pencairan = result.getOrElse(() => throw 'expected Right');
      expect(pencairan.id, 'p-1');
      expect(pencairan.nasabahNama, 'Ahmad Ridwan');
      expect(pencairan.nominal, 200000);
      expect(pencairan.metode, MetodePencairan.tunai);
      expect(pencairan.saldoSebelum, 465600);
      expect(pencairan.saldoSesudah, 265600);
      expect(pencairan.status, 'tercatat');
    });

    test('leaves out a blank keterangan', () async {
      Map<String, dynamic>? sent;
      when(() => network.post('/api/v1/pencairan', data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return _ok('/api/v1/pencairan', _pencairanJson());
      });

      await repository.createPencairan(
        PencairanRequest(
          nasabahId: 'n-1',
          nominal: 50000,
          metode: MetodePencairan.transfer,
          tanggal: DateTime.utc(2026, 9, 22),
          keterangan: '   ',
        ),
      );

      expect(sent!.containsKey('keterangan'), isFalse);
      expect(sent!['metode'], 'transfer');
    });

    test('surfaces a 422 as an UnprocessableEntityException', () async {
      when(() => network.post('/api/v1/pencairan', data: any(named: 'data')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/pencairan'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/v1/pencairan'),
            statusCode: 422,
            data: {
              'errors': {
                'nominal': ['Saldo nasabah tidak mencukupi'],
              },
            },
          ),
        ),
      );

      final result = await repository.createPencairan(
        PencairanRequest(
          nasabahId: 'n-1',
          nominal: 999999,
          metode: MetodePencairan.tunai,
          tanggal: DateTime.utc(2026, 9, 22),
        ),
      );

      final failure = result.swap().getOrElse(() => throw 'expected Left');
      expect(failure, isA<UnprocessableEntityException>());
      expect(failure.message, 'Saldo nasabah tidak mencukupi');
    });
  });

  group('getRiwayat', () {
    Map<String, dynamic>? sentParams;

    void stubList(List<Map<String, dynamic>> rows) {
      when(() => network.get('/api/v1/pencairan',
              queryParams: any(named: 'queryParams')))
          .thenAnswer((invocation) async {
        sentParams =
            invocation.namedArguments[#queryParams] as Map<String, dynamic>;
        return _ok('/api/v1/pencairan', {
          'count': rows.length,
          'next': null,
          'previous': null,
          'results': rows,
        });
      });
    }

    setUp(() => sentParams = null);

    test('asks for the whole history when the periode is semua', () async {
      stubList([
        {
          ..._pencairanJson(),
          'nasabah_id': 'n-1',
          'dicatat_oleh_nama': 'Ibu Sari',
        },
      ]);

      final result = await repository.getRiwayat(
        const RiwayatPencairanFilter(periode: RiwayatPeriode.semua),
      );

      expect(sentParams!.containsKey('periode'), isFalse);
      expect(sentParams!['page_size'], 100);
      final rows = result.getOrElse(() => throw 'expected Right');
      expect(rows, hasLength(1));
      expect(rows.single.id, 'p-1');
      expect(rows.single.nasabahId, 'n-1');
      expect(rows.single.dicatatOlehNama, 'Ibu Sari');
      expect(rows.single.nominal, 200000);
    });

    test('sends the periode, nasabah and search that are set', () async {
      stubList(const []);

      await repository.getRiwayat(
        const RiwayatPencairanFilter(
          periode: RiwayatPeriode.bulanIni,
          nasabahId: 'n-1',
          search: '  siti ',
        ),
      );

      expect(sentParams, {
        'periode': 'bulan_ini',
        'nasabah_id': 'n-1',
        'search': 'siti',
        'page_size': 100,
      });
    });
  });

  group('edit support', () {
    test('maps diperbarui and the earliest editable tanggal', () async {
      when(() => network.get('/api/v1/pencairan',
              queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => _ok('/api/v1/pencairan', {
                'count': 2,
                'results': [
                  {
                    ..._pencairanJson(),
                    'diperbarui': true,
                    'tanggal_edit_minimum': '2026-09-15T03:15:00Z',
                  },
                  {..._pencairanJson(), 'id': 'p-2'},
                ],
              }));

      final result =
          await repository.getRiwayat(const RiwayatPencairanFilter());

      final rows = result.getOrElse(() => throw 'expected Right');
      expect(rows.first.diperbarui, isTrue);
      expect(
        rows.first.tanggalEditMinimum,
        DateTime.utc(2026, 9, 15, 3, 15).toLocal(),
      );
      // Older backends omit both fields.
      expect(rows.last.diperbarui, isFalse);
      expect(rows.last.tanggalEditMinimum, isNull);
    });
  });

  group('editPencairan', () {
    test('patches every field with the alasan and maps the result', () async {
      Map<String, dynamic>? sent;
      when(() => network.patch('/api/v1/pencairan/p-1', data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return _ok('/api/v1/pencairan/p-1', {
          ..._pencairanJson(),
          'nominal': '150000.00',
          'saldo_sesudah': '315600.00',
          'diperbarui': true,
        });
      });

      final result = await repository.editPencairan(
        EditPencairanRequest(
          id: 'p-1',
          nominal: 150000,
          metode: MetodePencairan.transfer,
          tanggal: DateTime.utc(2026, 9, 21, 3, 15),
          keterangan: '  Ditransfer  ',
          alasan: '  Salah ketik  ',
        ),
      );

      expect(sent, {
        'nominal': 150000,
        'metode': 'transfer',
        'tanggal': '2026-09-21T03:15:00.000Z',
        'keterangan': 'Ditransfer',
        'alasan': 'Salah ketik',
      });
      final pencairan = result.getOrElse(() => throw 'expected Right');
      expect(pencairan.nominal, 150000);
      expect(pencairan.saldoSesudah, 315600);
      expect(pencairan.diperbarui, isTrue);
    });
  });

  group('getRevisi', () {
    test('maps the current pencairan and its replaced versions', () async {
      when(() => network.get('/api/v1/pencairan/p-1/riwayat')).thenAnswer(
        (_) async => _ok('/api/v1/pencairan/p-1/riwayat', {
          'pencairan': {
            ..._pencairanJson(),
            'nominal': '150000.00',
            'diperbarui': true,
          },
          'revisi': [
            {
              'versi': 1,
              'tanggal': '2026-09-22T03:15:00Z',
              'nominal': '200000.00',
              'metode': 'tunai',
              'keterangan': 'Diambil pagi',
              'saldo_sebelum': '465600.00',
              'saldo_sesudah': '265600.00',
              'alasan': 'Salah ketik nominal',
              'diubah_oleh': 'u-1',
              'diubah_oleh_nama': 'Ibu Sari',
              'diubah_pada': '2026-09-22T05:00:00Z',
            },
          ],
        }),
      );

      final result = await repository.getRevisi('p-1');

      final riwayat = result.getOrElse(() => throw 'expected Right');
      expect(riwayat.pencairan.nominal, 150000);
      final versi = riwayat.revisi.single;
      expect(versi.versi, 1);
      expect(versi.nominal, 200000);
      expect(versi.metode, MetodePencairan.tunai);
      expect(versi.saldoSesudah, 265600);
      expect(versi.alasan, 'Salah ketik nominal');
      expect(versi.diubahOlehNama, 'Ibu Sari');
      expect(versi.diubahPada, DateTime.utc(2026, 9, 22, 5).toLocal());
    });
  });
}
