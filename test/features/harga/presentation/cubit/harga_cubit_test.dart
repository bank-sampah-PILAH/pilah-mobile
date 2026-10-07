import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id, String kategori,
        {bool active = true, String harga = '2500'}) =>
    {
      'id': id,
      'kode': 'K-$id',
      'nama_sampah': 'Sampah $id',
      'kategori': kategori,
      'deskripsi': 'desk $id',
      'harga_per_kg': harga,
      'is_active': active,
    };

HargaEntity _entity() => HargaEntity(
      id: 'h1',
      kodeSampah: ' KD ',
      name: ' Botol ',
      price: 1500,
      priceFormatted: 'Rp 1500',
      category: 'Plastik',
      subtitle: ' bersih ',
      badgeText: 'Anorganik',
      icon: const IconData(0),
      iconColor: const Color(0xFF000000),
      isActive: true,
    );

void main() {
  late StubApi api;
  late HargaCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildHargaCubit(api);
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        _row('1', 'Kertas'),
        _row('2', 'plastik', harga: 'x'),
        _row('3', 'logam', active: false),
        _row('4', 'kaca'),
        _row('5', 'organik'),
        _row('6', 'lain'),
      ],
    });
  });

  tearDown(() => cubit.close());

  test('loads every status and shows the active tab first', () async {
    await cubit.loadHarga();

    expect(api.last.query, {'status': 'semua', 'page_size': '100'});
    final loaded = cubit.state as HargaLoaded;
    expect(loaded.jenisSampahList.map((e) => e.id), ['1', '2', '4', '5', '6']);
    expect(cubit.activeJenisSampah.length, 5);
  });

  test('maps each category to its icon, colour and badge', () async {
    await cubit.loadHarga();

    final byId = {
      for (final e in (cubit.state as HargaLoaded).jenisSampahList) e.id: e,
    };
    expect(byId['1']!.icon, Icons.description);
    expect(byId['2']!.icon, Icons.local_drink);
    expect(byId['2']!.price, 0);
    expect(byId['4']!.icon, Icons.wine_bar);
    expect(byId['5']!.badgeText, 'Organik');
    expect(byId['6']!.badgeText, 'Anorganik');
    expect(byId['1']!.priceFormatted, 'Rp 2500');
  });

  test('inactive tab shows only deactivated items, and tab state is kept',
      () async {
    await cubit.loadHarga();
    cubit.setActiveTab(false);

    final loaded = cubit.state as HargaLoaded;
    expect(loaded.jenisSampahList.map((e) => e.id), ['3']);
    expect(loaded.jenisSampahList.single.icon, Icons.hardware);
    expect(cubit.isActiveTab, isFalse);
  });

  test('search narrows by name or category, case-insensitively', () async {
    await cubit.loadHarga();

    cubit.searchHarga('KERTAS');
    expect(
        (cubit.state as HargaLoaded).jenisSampahList.map((e) => e.id), ['1']);
    cubit.searchHarga('sampah 4');
    expect(
        (cubit.state as HargaLoaded).jenisSampahList.map((e) => e.id), ['4']);
    expect(cubit.searchQuery, 'sampah 4');
  });

  test('a silent reload keeps the list on screen', () async {
    await cubit.loadHarga();
    final states = <HargaState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.loadHarga(silent: true);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states.whereType<HargaLoading>(), isEmpty);
    expect(states.last, isA<HargaLoaded>());
  });

  test('a failed load emits the backend message', () async {
    api.on('GET', '/api/v1/jenis-sampah',
        status: 400, json: {'error': 'Tidak diizinkan'});

    await cubit.loadHarga();

    expect(cubit.state, const HargaError('Tidak diizinkan'));
  });

  test('add posts only the writable, trimmed fields then reloads', () async {
    api.on('POST', '/api/v1/jenis-sampah', status: 201, json: {});

    final failure = await cubit.addHarga(_entity());
    await pumpEventQueue();

    expect(failure, isNull);
    final post = api.requests.firstWhere((r) => r.method == 'POST');
    expect(post.json, {
      'kode': 'KD',
      'nama_sampah': 'Botol',
      'kategori': 'plastik',
      'deskripsi': 'bersih',
      'harga_per_kg': '1500',
    });
    expect(api.requests.last.method, 'GET');
  });

  test('add returns the validation failure so the form can show it', () async {
    api.on('POST', '/api/v1/jenis-sampah', status: 422, json: {
      'errors': {
        'kode': ['Kode sudah dipakai']
      },
    });

    final failure = await cubit.addHarga(_entity());

    expect(failure, isA<UnprocessableEntityException>());
    expect(failure!.fieldError(['kode']), 'Kode sudah dipakai');
  });

  test('update puts to the record URL', () async {
    api.on('PUT', '/api/v1/jenis-sampah/h1', json: {});

    expect(await cubit.updateHarga(_entity()), isNull);
    await pumpEventQueue();
    expect(api.requests.any((r) => r.method == 'PUT'), isTrue);
  });

  test('update surfaces a failure', () async {
    api.on('PUT', '/api/v1/jenis-sampah/h1', status: 404, json: {'error': 'x'});

    expect(await cubit.updateHarga(_entity()), isA<NotFoundException>());
  });

  test('deactivate and activate toggle through the status endpoint', () async {
    api.on('PATCH', '/api/v1/jenis-sampah/h1/status', json: {});

    expect(await cubit.deactivateHarga('h1'), isNull);
    await pumpEventQueue();
    expect(api.requests.firstWhere((r) => r.method == 'PATCH').json,
        {'is_active': false});
    expect(await cubit.activateHarga('h1'), isNull);
    await pumpEventQueue();
    expect(api.requests.where((r) => r.method == 'PATCH').last.json,
        {'is_active': true});
  });

  test('deactivate and activate surface failures', () async {
    api.fail('PATCH', '/api/v1/jenis-sampah/h1/status');

    expect(
        await cubit.deactivateHarga('h1'), isA<ConnectionTimeOutException>());
    expect(await cubit.activateHarga('h1'), isA<ConnectionTimeOutException>());
  });

  test('reset forgets data, tab and search', () async {
    await cubit.loadHarga();
    cubit.setActiveTab(false);
    cubit.searchHarga('x');

    cubit.reset();

    expect(cubit.state, isA<HargaInitial>());
    expect(cubit.isActiveTab, isTrue);
    expect(cubit.searchQuery, '');
    expect(cubit.activeJenisSampah, isEmpty);
  });

  test('states with the same content are equal', () {
    expect(HargaInitial(), HargaInitial());
    expect(HargaLoading(), HargaLoading());
    expect(const HargaLoaded(jenisSampahList: []),
        const HargaLoaded(jenisSampahList: []));
    expect(const HargaError('a') == const HargaError('b'), isFalse);
  });

  test('a repository failure on get is reported as an error state', () async {
    api.fail('GET', '/api/v1/jenis-sampah', DioExceptionType.receiveTimeout);

    await cubit.loadHarga();

    expect(cubit.state, const HargaError('Receive Timeout'));
  });
}
