import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

NasabahRequest _request() => NasabahRequest(
      kode: ' NAS-9 ',
      nama: ' Siti ',
      email: ' siti@x.test ',
      jenisKelamin: 'Perempuan',
      tanggalLahir: '5/9/1990',
      noHp: '0812',
      alamat: ' Jl. Baru ',
    );

void main() {
  late StubApi api;
  late NasabahCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildNasabahCubit(api);
  });

  tearDown(() => cubit.close());

  test('loads the first page of active nasabah with the server count',
      () async {
    api.on('GET', _path,
        json: nasabahPage([nasabahRow('1')], count: 40, hasNext: true));

    await cubit.loadNasabah();

    expect(api.last.query, {'status': 'aktif', 'page': '1'});
    final loaded = cubit.state as NasabahLoaded;
    expect(loaded.nasabahList.single.name, 'Budi Santoso');
    expect(loaded.nasabahList.single.balance, 'Rp 25.000');
    expect(loaded.nasabahList.single.tanggalLahir, '17/04/1990');
    expect(loaded.totalCount, 40);
    expect(loaded.hasMore, isTrue);
    expect(cubit.activeCount, 40);
  });

  test('maps sparse rows to safe defaults', () async {
    api.on('GET', _path, json: nasabahPage([<String, dynamic>{}]));

    await cubit.loadNasabah();

    final n = (cubit.state as NasabahLoaded).nasabahList.single;
    expect(n.id, '');
    expect(n.balance, 'Rp 0');
    expect(n.isActive, isTrue);
    expect(n.status, 'approved');
    expect(n.jenisKelamin, '');
  });

  test('a response without results is an empty page', () async {
    api.on('GET', _path, json: <String, dynamic>{});

    await cubit.loadNasabah();

    expect((cubit.state as NasabahLoaded).nasabahList, isEmpty);
  });

  test('a failed load is an error state', () async {
    api.on('GET', _path, status: 403, json: {'error': 'Tidak diizinkan'});

    await cubit.loadNasabah();

    expect(cubit.state, const NasabahError('Tidak diizinkan'));
  });

  test('load more appends the next page', () async {
    api.on('GET', _path,
        json: nasabahPage([nasabahRow('1')], count: 2, hasNext: true));
    await cubit.loadNasabah();
    api.on('GET', _path, json: nasabahPage([nasabahRow('2')], count: 2));

    await cubit.loadMoreNasabah();

    expect(api.last.query['page'], '2');
    final loaded = cubit.state as NasabahLoaded;
    expect(loaded.nasabahList.map((n) => n.id), ['1', '2']);
    expect(loaded.hasMore, isFalse);
  });

  test('a failed load-more keeps what is already shown', () async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')], hasNext: true));
    await cubit.loadNasabah();
    api.fail('GET', _path);

    await cubit.loadMoreNasabah();

    expect((cubit.state as NasabahLoaded).nasabahList, hasLength(1));
    expect((cubit.state as NasabahLoaded).isLoadingMore, isFalse);
  });

  test('load more does nothing without more pages', () async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
    await cubit.loadNasabah();
    final calls = api.requests.length;

    await cubit.loadMoreNasabah();

    expect(api.requests.length, calls);
  });

  test('the picker list only offers approved, active nasabah', () async {
    api.on('GET', _path,
        json: nasabahPage([
          nasabahRow('1'),
          nasabahRow('2', active: false),
          nasabahRow('3', status: 'pending'),
        ]));

    final list = await cubit.loadActiveNasabah();

    expect(list.map((n) => n.id), ['1']);
    expect(api.last.query, {'status': 'aktif', 'page_size': '100'});
    expect(cubit.activeNasabah.map((n) => n.id), ['1']);
  });

  test('the picker list throws the failure so the caller can show it',
      () async {
    api.on('GET', _path, status: 500, json: {});

    await expectLater(cubit.loadActiveNasabah(), throwsA(anything));
  });

  test('switching tab refetches with that tab\'s status', () async {
    api.on('GET', _path, json: nasabahPage([]));
    await cubit.setActiveTab(false);
    expect(api.last.query['status'], 'tidak_aktif');
    expect(cubit.isActiveTab, isFalse);

    await cubit.setActiveTab(null);
    expect(api.last.query['status'], 'menunggu');

    final calls = api.requests.length;
    await cubit.setActiveTab(null);
    expect(api.requests.length, calls);
  });

  test('searching waits out the debounce and needs two characters', () async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
    await cubit.loadNasabah();
    final calls = api.requests.length;

    cubit.searchNasabah('b');
    cubit.searchNasabah('b');
    await Future<void>.delayed(NasabahCubit.jedaPencarian * 2);
    expect(api.requests.length, calls + 1);
    expect(api.last.query.containsKey('search'), isFalse);

    cubit.searchNasabah('bu');
    await Future<void>.delayed(NasabahCubit.jedaPencarian * 2);
    expect(api.last.query['search'], 'bu');
    expect(cubit.searchQuery, 'bu');
  });

  test('adding a nasabah posts the payload and reloads the list', () async {
    api.on('GET', _path, json: nasabahPage([]));
    api.on('POST', _path, status: 201, json: nasabahRow('9'));

    final error = await cubit.addNasabah(_request());

    expect(error, isNull);
    final post = api.requests.firstWhere((r) => r.method == 'POST');
    expect(post.json, {
      'kode': 'NAS-9',
      'nama': 'Siti',
      'email': 'siti@x.test',
      'jenis_kelamin': 'perempuan',
      'tanggal_lahir': '1990-09-05',
      'no_hp': '0812',
      'alamat': 'Jl. Baru',
    });
    expect(api.last.method, 'GET');
  });

  test('add hands back a validation failure without reloading', () async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'kode': ['Kode sudah dipakai']
      },
    });

    final error = await cubit.addNasabah(_request());

    expect(error!.fieldError(['kode']), 'Kode sudah dipakai');
    expect(api.requests.where((r) => r.method == 'GET'), isEmpty);
  });

  test('updating puts to the nasabah and refreshes the active count off-tab',
      () async {
    api.on('GET', _path, json: nasabahPage([], count: 7));
    api.on('PUT', '$_path/n1', json: nasabahRow('n1'));
    await cubit.setActiveTab(false);

    final error = await cubit.updateNasabah('n1', _request());

    expect(error, isNull);
    // Off the active tab, the active total is fetched separately.
    expect(api.requests.where((r) => r.query['status'] == 'aktif'), isNotEmpty);
    expect(cubit.activeCount, 7);
  });

  test('an update failure is returned', () async {
    api.on('PUT', '$_path/n1', status: 404, json: {'error': 'Tidak ada'});

    expect((await cubit.updateNasabah('n1', _request()))!.displayMessage,
        'Tidak ada');
  });

  test('activating and deactivating toggle through the status endpoint',
      () async {
    api.on('GET', _path, json: nasabahPage([]));
    api.on('PATCH', '$_path/n1/status', json: {});

    expect(await cubit.setNasabahStatus('n1', false), isNull);
    expect(api.requests.firstWhere((r) => r.method == 'PATCH').json,
        {'is_active': false});
    expect(await cubit.setNasabahStatus('n1', true), isNull);
    expect(api.requests.where((r) => r.method == 'PATCH').last.json,
        {'is_active': true});
  });

  test('a failed status change is returned', () async {
    api.fail('PATCH', '$_path/n1/status', DioExceptionType.connectionTimeout);

    expect(await cubit.setNasabahStatus('n1', true), isNotNull);
    expect(await cubit.setNasabahStatus('n1', false), isNotNull);
  });

  test('approving and rejecting send the trimmed note', () async {
    api.on('GET', _path, json: nasabahPage([]));
    api.on('POST', '$_path/n1/approve', json: {});
    api.on('POST', '$_path/n1/reject', json: {});

    expect(await cubit.decideNasabah('n1', approve: true, catatan: ' ok '),
        isNull);
    expect(api.requests.firstWhere((r) => r.path.endsWith('/approve')).json,
        {'catatan': 'ok'});

    expect(await cubit.decideNasabah('n1', approve: false), isNull);
    expect(api.requests.firstWhere((r) => r.path.endsWith('/reject')).json,
        <String, dynamic>{});

    expect(
        await cubit.decideNasabah('n1',
            approve: false, catatan: ' data palsu '),
        isNull);
    expect(api.requests.where((r) => r.path.endsWith('/reject')).last.json,
        {'catatan': 'data palsu'});
  });

  test('a failed decision is returned', () async {
    api.on('POST', '$_path/n1/approve', status: 409, json: {'error': 'Sudah'});
    api.on('POST', '$_path/n1/reject', status: 409, json: {'error': 'Sudah'});

    expect((await cubit.decideNasabah('n1', approve: true))!.displayMessage,
        'Sudah');
    expect((await cubit.decideNasabah('n1', approve: false))!.displayMessage,
        'Sudah');
  });

  test('syncing the profile posts and reloads', () async {
    api.on('GET', _path, json: nasabahPage([]));
    api.on('POST', '$_path/n1/sinkron-profil', json: {});

    expect(await cubit.sinkronProfil('n1'), isNull);
    expect(api.requests.any((r) => r.path.endsWith('/sinkron-profil')), isTrue);
  });

  test('a failed sync is returned', () async {
    api.on('POST', '$_path/n1/sinkron-profil',
        status: 403, json: {'error': 'Ditolak'});

    expect((await cubit.sinkronProfil('n1'))!.displayMessage, 'Ditolak');
  });

  test('the summary carries the account profile and differences', () async {
    api.on('GET', '$_path/n1', json: {
      'ringkasan_transaksi': {
        'jumlah_transaksi': 3,
        'total_kg': '12.5',
        'tanggal_transaksi_terakhir': '2026-09-01T00:00:00Z',
      },
      'profil_akun': {
        'nama': 'Siti',
        'jenis_kelamin': 'perempuan',
        'tanggal_lahir': '1998-05-17',
        'alamat': 'Jl. A',
        'no_hp': '0812',
      },
      'profil_berbeda': ['nama', 'alamat'],
    });

    final ringkasan = (await cubit.fetchRingkasan('n1'))!;

    expect(ringkasan.jumlahTransaksi, 3);
    expect(ringkasan.totalKg, '12,5');
    expect(ringkasan.profilAkun!.jenisKelamin, 'Perempuan');
    expect(ringkasan.profilBerbeda, ['nama', 'alamat']);
  });

  test('a bare summary and a failed one', () async {
    api.on('GET', '$_path/n1', json: <String, dynamic>{});
    final bare = (await cubit.fetchRingkasan('n1'))!;
    expect(bare.jumlahTransaksi, 0);
    expect(bare.profilAkun, isNull);

    api.on('GET', '$_path/n1', status: 404, json: {});
    expect(await cubit.fetchRingkasan('n1'), isNull);
  });

  test('states with the same content are equal', () {
    expect(NasabahInitial(), NasabahInitial());
    expect(NasabahInitial().props, isEmpty);
    expect(const NasabahError('a') == const NasabahError('a'), isTrue);
  });

  test('reset forgets the list, tab and search', () async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
    await cubit.loadNasabah();
    await cubit.setActiveTab(false);

    cubit.reset();

    expect(cubit.state, isA<NasabahInitial>());
    expect(cubit.isActiveTab, isTrue);
    expect(cubit.activeNasabah, isEmpty);
    expect(cubit.activeCount, 0);
  });

  test('a silent reload keeps the list without a spinner', () async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
    await cubit.loadNasabah();
    final states = <NasabahState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.loadNasabah(silent: true);
    await pumpEventQueue();
    await sub.cancel();

    expect(states.whereType<NasabahLoading>(), isEmpty);
    expect(
        states.whereType<NasabahLoaded>().any((s) => s.isReloading), isFalse);
  });

  test('a normal reload over a loaded list flags it as reloading', () async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
    await cubit.loadNasabah();
    final states = <NasabahState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.loadNasabah();
    await pumpEventQueue();
    await sub.cancel();

    expect(states.whereType<NasabahLoaded>().first.isReloading, isTrue);
  });
}
