import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_state.dart';

import '../../../../support/pengumuman_support.dart';
import '../../../../support/stub_api.dart';

PengumumanEntity _entity(String judul, {String id = ''}) => PengumumanEntity(
      id: id,
      bankSampahId: '',
      judul: judul,
      isi: 'Isi pengumuman.',
    );

Map<String, dynamic> _row(String id, {String status = 'terbit'}) => {
      'id': id,
      'bank_sampah_id': 'bank-1',
      'judul': 'Pengumuman $id',
      'isi': 'Isi $id',
      'terbit_pada': '2026-10-15T03:00:00Z',
      'masa_berlaku_hingga': null,
      'ditarik_pada': null,
      'status': status,
    };

void main() {
  late StubApi api;
  late PengumumanCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildPengumumanCubit(api);
  });

  tearDown(() => cubit.close());

  test('loads the first page and keeps the derived status', () async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1'), _row('2', status: 'terjadwal')],
    });

    await cubit.loadPengumuman();

    final loaded = cubit.state as PengumumanLoaded;
    expect(loaded.items, hasLength(2));
    expect(loaded.items[0].status, 'terbit');
    expect(loaded.items[1].isTerjadwal, isTrue);
    expect(loaded.hasMore, isFalse);
    expect(loaded.totalCount, 2);
    expect(api.last.path, '/api/v1/pengumuman');
  });

  test('sends the status filter when one is set', () async {
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});

    await cubit.loadPengumuman(status: 'draft');

    expect(api.last.query['status'], 'draft');
    expect(cubit.state, isA<PengumumanLoaded>());
    expect((cubit.state as PengumumanLoaded).items, isEmpty);
  });

  test('paginates with the next-page sentinel', () async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 3,
      'next': 'http://api.test/api/v1/pengumuman?page=2',
      'results': [_row('1')],
    });
    await cubit.loadPengumuman();

    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 3,
      'next': null,
      'results': [_row('2')],
    });
    await cubit.loadNextPage();

    final loaded = cubit.state as PengumumanLoaded;
    expect(loaded.items.map((item) => item.id), ['1', '2']);
    expect(loaded.hasMore, isFalse);
  });

  test('pagination keeps existing rows and filters overlapping IDs', () async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 2,
      'next': 'http://api.test/api/v1/pengumuman?page=2',
      'results': [_row('1')],
    });
    await cubit.loadPengumuman();

    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1', status: 'draft'), _row('2')],
    });
    await cubit.loadNextPage();

    final loaded = cubit.state as PengumumanLoaded;
    expect(loaded.items.map((item) => item.id), ['1', '2']);
    expect(loaded.items.first.status, 'terbit');
  });

  test('create saves a draft and update patches the saved row', () async {
    api.on('POST', '/api/v1/pengumuman', json: _row('9', status: 'draft'));
    api.on('PATCH', '/api/v1/pengumuman/9', json: _row('9', status: 'draft'));
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});

    final created = await cubit.savePengumuman(_entity('Kerja bakti'));
    expect(created.fold((_) => null, (item) => item.id), '9');

    final updated = await cubit.savePengumuman(_entity('Kerja bakti', id: '9'));
    expect(updated.fold((_) => null, (item) => item.id), '9');
    expect(api.requests.any((call) => call.method == 'PATCH'), isTrue);
  });

  test('terbitkan posts the action and tarik posts its own', () async {
    api.on('POST', '/api/v1/pengumuman/9/terbitkan', json: _row('9'));
    api.on('POST', '/api/v1/pengumuman/9/tarik',
        json: _row('9', status: 'ditarik'));
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});

    await cubit.terbitkan('9');
    expect(
      api.requests.any((call) =>
          call.method == 'POST' &&
          call.path == '/api/v1/pengumuman/9/terbitkan'),
      isTrue,
    );

    await cubit.tarik('9');
    expect(
      api.requests.any((call) =>
          call.method == 'POST' && call.path == '/api/v1/pengumuman/9/tarik'),
      isTrue,
    );
  });

  test('a failed transition surfaces the message and keeps the list', () async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await cubit.loadPengumuman();

    api.on('POST', '/api/v1/pengumuman/1/tarik',
        status: 400,
        json: {'error': 'Perubahan status pengumuman tidak diizinkan'});
    final failure = await cubit.tarik('1');

    expect(failure, isNotNull);
    final loaded = cubit.state as PengumumanLoaded;
    expect(loaded.items, hasLength(1));
  });

  test('deletePengumuman posts the delete and reloads silently', () async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', status: 'draft')],
    });
    await cubit.loadPengumuman();

    api.on('DELETE', '/api/v1/pengumuman/1', json: null);
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
    final failure = await cubit.deletePengumuman('1');

    expect(failure, isNull);
    expect(
      api.requests.any((call) => call.method == 'DELETE'),
      isTrue,
    );
    final loaded = cubit.state as PengumumanLoaded;
    expect(loaded.items, isEmpty);
  });

  test('a save that fails after its session was reset rethrows the failure',
      () async {
    api.latency = const Duration(seconds: 1);
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
    // No POST route: the save fails with not-found, after the reset below.

    final pending = cubit.savePengumuman(_entity('Nih'));
    cubit.reset();
    final outcome = await pending;

    // The stale failure forwards unchanged instead of the session message.
    expect(outcome.fold((f) => f.displayMessage, (_) => null),
        'no stub for POST /api/v1/pengumuman');
    api.latency = null;
  });

  test('a failed next page keeps the rows and shows the loading-more error',
      () async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 2,
      'next': 'http://api.test/api/v1/pengumuman?page=2',
      'results': [_row('1')],
    });
    await cubit.loadPengumuman();

    api.fail('GET', '/api/v1/pengumuman');
    await cubit.loadNextPage();

    final loaded = cubit.state as PengumumanLoaded;
    expect(loaded.items, hasLength(1));
    expect(loaded.isLoadingMore, isFalse);
    expect(loaded.loadingMoreError, isNotEmpty);
  });

  test('a second save while one runs is refused', () async {
    api.latency = const Duration(seconds: 1);
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});

    final first = cubit.savePengumuman(_entity('Pertama'));
    final second = await cubit.savePengumuman(_entity('Kedua'));
    expect(second.fold((failure) => failure.displayMessage, (_) => null),
        'Tunggu proses pengumuman selesai sebelum menyimpan.');
    await first;
    api.latency = null;
  });

  test('a save after reset reports the session change', () async {
    api.latency = const Duration(seconds: 1);
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
    api.on('POST', '/api/v1/pengumuman', json: _row('9', status: 'draft'));

    final pending = cubit.savePengumuman(_entity('Terlambat'));
    cubit.reset();
    final outcome = await pending;
    expect(outcome.fold((failure) => failure.displayMessage, (_) => null),
        'Sesi berubah, simpan ulang pengumuman.');
    api.latency = null;
  });

  test('a transition started before a reset returns without reloading the list',
      () async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await cubit.loadPengumuman();
    final getsBefore = api.requests
        .where(
            (call) => call.method == 'GET' && call.path == '/api/v1/pengumuman')
        .length;

    api.on('POST', '/api/v1/pengumuman/1/tarik',
        json: _row('1', status: 'ditarik'));
    api.latency = const Duration(seconds: 1);
    final pending = cubit.tarik('1');
    cubit.reset();
    final failure = await pending;
    api.latency = null;

    // The reset replaced the state; the transition does not reload into it.
    final getsAfter = api.requests
        .where(
            (call) => call.method == 'GET' && call.path == '/api/v1/pengumuman')
        .length;
    expect(getsAfter, getsBefore);
    expect(failure, isNull);
  });
}
