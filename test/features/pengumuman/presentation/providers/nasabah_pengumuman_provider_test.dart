import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/states/nasabah_pengumuman_state.dart';

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
  late ProviderContainer container;
  late ProviderSubscription<NasabahPengumumanState> subscription;
  late NasabahPengumumanNotifier notifier;

  setUp(() {
    api = StubApi();
    container = ProviderContainer(overrides: [
      nasabahPengumumanProvider.overrideWith(
        () => NasabahPengumumanNotifier(
          NasabahPengumumanRepository(api.network),
        ),
      ),
    ]);
    subscription = container.listen(
      nasabahPengumumanProvider,
      (_, __) {},
    );
    notifier = container.read(nasabahPengumumanProvider.notifier);
    addTearDown(subscription.close);
    addTearDown(container.dispose);
  });

  test('loads page one with read flags from the backend', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1'), _row('2', dibaca: true)],
    });

    await notifier.load();

    final state = container.read(nasabahPengumumanProvider);
    expect(state.status, NasabahPengumumanStatus.loaded);
    expect(state.items, hasLength(2));
    expect(state.items[0].dibaca, isFalse);
    expect(state.items[1].dibaca, isTrue);
  });

  test('sends keanggotaan_id when a membership is set', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});

    await notifier.load(membershipId: 'm-1');

    expect(api.last.query['keanggotaan_id'], 'm-1');
  });

  test('paginates with the next sentinel and dedupes ids', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': 'http://api.test/api/v1/nasabah/me/pengumuman?page=2',
      'results': [_row('1')],
    });
    await notifier.load();

    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1'), _row('2')],
    });
    await notifier.loadNextPage();

    final state = container.read(nasabahPengumumanProvider);
    expect(state.items.map((item) => item.id), ['1', '2']);
    expect(state.hasNext, isFalse);
  });

  test('tandaiDibaca posts and flips the row locally', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await notifier.load();

    api.on('POST', '/api/v1/nasabah/me/pengumuman/1/baca', json: {
      'id': '1',
      'dibaca': true,
      'dibaca_pada': '2026-10-15T06:00:00Z',
    });
    await notifier.tandaiDibaca('1');

    expect(
      api.requests
          .any((call) => call.path == '/api/v1/nasabah/me/pengumuman/1/baca'),
      isTrue,
    );
    expect(
        container.read(nasabahPengumumanProvider).items.single.dibaca, isTrue);
  });

  test('a list failure surfaces the Indonesian message', () async {
    api.fail('GET', '/api/v1/nasabah/me/pengumuman');

    await notifier.load();

    expect(container.read(nasabahPengumumanProvider).status,
        NasabahPengumumanStatus.failure);
    expect(container.read(nasabahPengumumanProvider).error, isNotEmpty);
  });

  test('a next-page failure surfaces its message and clears the spinner',
      () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': 'http://api.test/api/v1/nasabah/me/pengumuman?page=2',
      'results': [_row('1')],
    });
    await notifier.load();

    api.fail('GET', '/api/v1/nasabah/me/pengumuman');
    await notifier.loadNextPage();

    final state = container.read(nasabahPengumumanProvider);
    expect(state.status, NasabahPengumumanStatus.loaded);
    expect(state.isLoadingMore, isFalse);
    expect(state.error, isNotEmpty);
    expect(state.items, hasLength(1));
  });

  test('a failed read-marker keeps the list as it is', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await notifier.load();

    api.fail('POST', '/api/v1/nasabah/me/pengumuman/1/baca');
    await notifier.tandaiDibaca('1');

    expect(
        container.read(nasabahPengumumanProvider).items.single.dibaca, isFalse);
  });

  test('marking one read leaves the other rows untouched', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1'), _row('2')],
    });
    await notifier.load();
    final second = container.read(nasabahPengumumanProvider).items[1];

    api.on('POST', '/api/v1/nasabah/me/pengumuman/1/baca',
        json: {'id': '1', 'dibaca': true});
    await notifier.tandaiDibaca('1');

    final items = container.read(nasabahPengumumanProvider).items;
    expect(items[0].dibaca, isTrue);
    // The untouched row keeps its identity, not a copy.
    expect(identical(items[1], second), isTrue);
  });

  test('invalidation resets to the initial state', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await notifier.load();
    expect(container.read(nasabahPengumumanProvider).status,
        NasabahPengumumanStatus.loaded);

    container.invalidate(nasabahPengumumanProvider);

    expect(container.read(nasabahPengumumanProvider).status,
        NasabahPengumumanStatus.initial);
  });
}
