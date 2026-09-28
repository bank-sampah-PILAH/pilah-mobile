import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';

class _Network extends Mock implements NetworkService {}

class _Environment extends Mock implements AppEnvironment {}

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

  test('setoran detail is loaded for the selected membership', () async {
    const id = '6b4c70b3-fd54-481b-a0a7-cbe06695fd83';
    const path = '/api/v1/nasabah/me/riwayat/$id';
    respond(path, {
      'id': id,
      'tanggal': '2026-09-23T09:00:00Z',
      'tipe': 'setoran',
      'total_nilai': '5000.00',
      'catatan': 'Setoran rutin',
      'saldo_setelah_transaksi': '15000.00',
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

    final detail = await repository.setoranDetail('member-b', id);

    expect(detail.amount, '5000.00');
    expect(detail.balanceAfter, '15000.00');
    expect(detail.items.single.name, 'Plastik PET');
    expect(detail.items.single.weight, '1.000');
    verify(() => network.get(path, queryParams: {'keanggotaan_id': 'member-b'}))
        .called(1);
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

  test('bank details resolve a relative logo against the API origin', () async {
    final environment = _Environment();
    when(() => environment.baseUrl).thenReturn('https://example.test');
    when(() => network.environment).thenReturn(environment);
    respond('/api/v1/nasabah/me/bank-sampah', {
      'nama': 'Mawar',
      'foto_logo': '/media/bank_sampah/logo/mawar.png',
    });
    final bank = await repository.bank('b');
    expect(
        bank.logoUrl, 'https://example.test/media/bank_sampah/logo/mawar.png');
  });

  test('bank details leave an absolute logo untouched and empty logo null',
      () async {
    respond('/api/v1/nasabah/me/bank-sampah',
        {'nama': 'Mawar', 'foto_logo': 'https://cdn.example.test/logo.png'});
    expect((await repository.bank('b')).logoUrl,
        'https://cdn.example.test/logo.png');
    respond('/api/v1/nasabah/me/bank-sampah', {'nama': 'Mawar'});
    expect((await repository.bank('b')).logoUrl, isNull);
  });

  test('bank details carry the organization type for unit/induk labelling',
      () async {
    respond('/api/v1/nasabah/me/bank-sampah',
        {'nama': 'Mawar', 'jenis_organisasi': 'unit'});
    expect((await repository.bank('b')).organizationType, 'unit');
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

  test('profile parses the full editable-field contract', () async {
    respond('/api/v1/nasabah/me/profil', {
      'id': 'u',
      'nama': 'API name',
      'email': 'api@example.test',
      'no_hp': '081234567890',
      'jenis_kelamin': 'perempuan',
      'tanggal_lahir': '1998-05-17',
      'alamat': 'Jl. Melati No. 1',
      'role': 'nasabah'
    });
    final identity = await repository.profile();
    expect(identity.noHp, '081234567890');
    expect(identity.jenisKelamin, 'perempuan');
    expect(identity.tanggalLahir, DateTime(1998, 5, 17));
    expect(identity.alamat, 'Jl. Melati No. 1');
  });

  test('profile tolerates null/empty optional fields', () async {
    respond('/api/v1/nasabah/me/profil', {
      'id': 'u',
      'nama': 'API name',
      'email': 'api@example.test',
      'no_hp': '',
      'jenis_kelamin': '',
      'tanggal_lahir': null,
      'alamat': '',
      'role': 'nasabah'
    });
    final identity = await repository.profile();
    expect(identity.noHp, '');
    expect(identity.jenisKelamin, '');
    expect(identity.tanggalLahir, isNull);
    expect(identity.alamat, '');
  });

  test('updateProfile patches only the given fields and returns the result',
      () async {
    when(
        () => network.patch('/api/v1/nasabah/me/profil', data: {
              'nama': 'New name',
              'no_hp': '0811'
            })).thenAnswer((_) async => Response(data: {
          'id': 'u',
          'nama': 'New name',
          'email': 'api@example.test',
          'no_hp': '0811',
          'jenis_kelamin': '',
          'tanggal_lahir': null,
          'alamat': '',
          'role': 'nasabah'
        }, requestOptions: RequestOptions(path: '/api/v1/nasabah/me/profil')));
    final identity =
        await repository.updateProfile(nama: 'New name', noHp: '0811');
    expect(identity.name, 'New name');
    expect(identity.noHp, '0811');
    verify(() => network.patch('/api/v1/nasabah/me/profil',
        data: {'nama': 'New name', 'no_hp': '0811'})).called(1);
  });

  test('updateProfile sends tanggal_lahir as a plain date, not a datetime',
      () async {
    when(
        () => network.patch('/api/v1/nasabah/me/profil', data: {
              'tanggal_lahir': '1998-05-17'
            })).thenAnswer((_) async => Response(data: {
          'id': 'u',
          'nama': 'API name',
          'email': 'api@example.test',
          'no_hp': '',
          'jenis_kelamin': '',
          'tanggal_lahir': '1998-05-17',
          'alamat': '',
          'role': 'nasabah'
        }, requestOptions: RequestOptions(path: '/api/v1/nasabah/me/profil')));
    await repository.updateProfile(tanggalLahir: DateTime(1998, 5, 17));
    verify(() => network.patch('/api/v1/nasabah/me/profil',
        data: {'tanggal_lahir': '1998-05-17'})).called(1);
  });

  test('updateProfile surfaces a validation error on 400', () async {
    when(() => network.patch(any(), data: any(named: 'data'))).thenThrow(
        DioException(
            requestOptions: RequestOptions(),
            response: Response(
                requestOptions: RequestOptions(),
                statusCode: 400,
                data: {
                  'no_hp': ['Nomor HP tidak valid.']
                })));
    await expectLater(
        repository.updateProfile(noHp: 'bad'),
        throwsA(isA<NasabahApiException>()
            .having((e) => e.message, 'message', isNot(contains('no_hp')))));
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
