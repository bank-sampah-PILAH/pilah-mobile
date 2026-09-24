import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';

class _Network extends Mock implements NetworkService {}

void main() {
  late _Network network;
  late NasabahRepository repository;
  setUp(() {
    network = _Network();
    repository = NasabahRepository(network);
  });

  void respond(String path, Map<String, dynamic> data) {
    when(() => network.get(path, queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async =>
            Response(data: data, requestOptions: RequestOptions(path: path)));
  }

  test(
      'home parses backend decimal, identity, bank and empty activity contract',
      () async {
    respond('/api/v1/nasabah/me/beranda', {
      'user': {
        'id': 'u',
        'nama': 'Siti',
        'email': 'siti@example.test',
        'role': 'nasabah'
      },
      'keanggotaan': {'id': 'membership'},
      'bank_sampah': {
        'nama': 'Melati',
        'alamat': 'Depok',
        'kota': 'Depok',
        'no_hp_pic': '08123'
      },
      'saldo': {'total_saldo': '12500.50', 'updated_at': null},
      'aktivitas_terbaru': [],
    });
    final home = await repository.home(membershipId: 'membership');
    expect(home.balance.amount, '12500.50');
    expect(home.identity.name, 'Siti');
    expect(home.activities, isEmpty);
    verify(() => network.get('/api/v1/nasabah/me/beranda',
        queryParams: {'keanggotaan_id': 'membership'})).called(1);
  });

  test('every history page retains membership and ignores next URL host',
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
    final history = await repository.history('member-b', page: 2);
    expect(history.hasNext, isTrue);
    expect(history.activities.single.amount, '5000.00');
    verify(() => network.get('/api/v1/nasabah/me/riwayat',
        queryParams: {'keanggotaan_id': 'member-b', 'page': 2})).called(1);
  });

  test('balance and bank details are scoped to selected membership', () async {
    respond('/api/v1/nasabah/me/saldo',
        {'total_saldo': '0.00', 'updated_at': null});
    respond('/api/v1/nasabah/me/bank-sampah', {'nama': 'Mawar'});
    expect((await repository.balance('b')).amount, '0.00');
    expect((await repository.bank('b')).name, 'Mawar');
    for (final path in ['saldo', 'bank-sampah']) {
      verify(() => network.get('/api/v1/nasabah/me/$path',
          queryParams: {'keanggotaan_id': 'b'})).called(1);
    }
  });

  test('profile uses nasabah endpoint without membership parameters', () async {
    respond('/api/v1/nasabah/me/profil', {
      'id': 'u',
      'nama': 'API name',
      'email': 'api@example.test',
      'role': 'nasabah'
    });
    expect((await repository.profile()).name, 'API name');
    verify(() => network.get('/api/v1/nasabah/me/profil',
        queryParams: <String, dynamic>{})).called(1);
  });

  test('422 parses membership choices from backend errors envelope', () async {
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
        repository.home(),
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
          repository.home(),
          throwsA(isA<NasabahApiException>().having(
              (e) => e.message, 'message', isNot(contains('private detail')))));
    });
  }

  test('decimal currency display keeps precision', () {
    expect(nasabahRupiah('12500.50'), 'Rp 12.500,50');
    expect(nasabahRupiah('0.00'), 'Rp 0');
    expect(nasabahRupiah('999999999999.99'), 'Rp 999.999.999.999,99');
  });
}
