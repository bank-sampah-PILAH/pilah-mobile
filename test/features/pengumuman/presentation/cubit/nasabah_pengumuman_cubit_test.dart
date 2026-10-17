import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_state.dart';

import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id, {bool dibaca = false}) => {
      'id': id,
      'judul': 'Pengumuman $id',
      'isi': 'Isi $id',
      'terbit_pada': '2026-10-15T03:00:00Z',
      'dibaca': dibaca,
      'dibaca_pada': dibaca ? '2026-10-15T05:00:00Z' : null,
    };

void main() {
  late StubApi api;
  late NasabahPengumumanCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = NasabahPengumumanCubit(NasabahPengumumanRepository(api.network));
  });

  tearDown(() => cubit.close());

  test('loads page one with read flags from the backend', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1'), _row('2', dibaca: true)],
    });

    await cubit.load();

    final state = cubit.state;
    expect(state.status, NasabahPengumumanStatus.loaded);
    expect(state.items, hasLength(2));
    expect(state.items[0].dibaca, isFalse);
    expect(state.items[1].dibaca, isTrue);
  });

  test('sends keanggotaan_id when a membership is set', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {'count': 0, 'next': null, 'results': []});

    await cubit.load(membershipId: 'm-1');

    expect(api.last.query['keanggotaan_id'], 'm-1');
  });

  test('paginates with the next sentinel and dedupes ids', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': 'http://api.test/api/v1/nasabah/me/pengumuman?page=2',
      'results': [_row('1')],
    });
    await cubit.load();

    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1'), _row('2')],
    });
    await cubit.loadNextPage();

    final state = cubit.state;
    expect(state.items.map((item) => item.id), ['1', '2']);
    expect(state.hasNext, isFalse);
  });

  test('tandaiDibaca posts and flips the row locally', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await cubit.load();

    api.on('POST', '/api/v1/nasabah/me/pengumuman/1/baca', json: {
      'id': '1',
      'dibaca': true,
      'dibaca_pada': '2026-10-15T06:00:00Z',
    });
    await cubit.tandaiDibaca('1');

    expect(
      api.requests.any((call) => call.path == '/api/v1/nasabah/me/pengumuman/1/baca'),
      isTrue,
    );
    expect(cubit.state.items.single.dibaca, isTrue);
  });

  test('a list failure surfaces the Indonesian message', () async {
    api.fail('GET', '/api/v1/nasabah/me/pengumuman');

    await cubit.load();

    expect(cubit.state.status, NasabahPengumumanStatus.failure);
    expect(cubit.state.error, isNotEmpty);
  });
}
