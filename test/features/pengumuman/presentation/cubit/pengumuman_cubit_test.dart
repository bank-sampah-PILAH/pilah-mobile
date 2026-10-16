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
}
