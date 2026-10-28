import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_urutan.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/notifier_harness.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

void main() {
  late StubApi api;
  late NotifierHarness<NasabahNotifier, NasabahState> harness;
  late NasabahNotifier notifier;

  setUp(() {
    api = StubApi();
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
    harness = NotifierHarness(nasabahProvider, () => buildNasabahNotifier(api));
    notifier = harness.notifier;
  });
  tearDown(() => harness.dispose());

  for (final (tab, status) in [
    (true, 'aktif'),
    (false, 'tidak_aktif'),
    (null, 'menunggu')
  ]) {
    for (final (query, order) in [
      ('budi', NasabahUrutan.nomor),
      ('', NasabahUrutan.nama),
      ('budi', NasabahUrutan.saldoTerbesar),
    ]) {
      test('reset search=$query order=$order preserves $status and page size',
          () async {
        await notifier.loadNasabah(pageSize: 10);
        await notifier.setActiveTab(tab);
        notifier.searchNasabah(query);
        await notifier.setUrutan(order);

        expect(notifier.hasActiveFilters, isTrue);
        await notifier.resetFilters();

        final state = notifier.state as NasabahLoaded;
        expect(notifier.searchQuery, isEmpty);
        expect(notifier.urutan, NasabahUrutan.nomor);
        expect(state.searchQuery, isEmpty);
        expect(state.urutan, NasabahUrutan.nomor);
        expect(state.isActiveTab, tab);
        expect(state.currentPage, 1);
        expect(state.pageSize, 10);
        expect(state.hasActiveFilters, isFalse);
        expect(api.last.query['search'], isNull);
        expect(api.last.query['urutan'], 'nomor');
        expect(api.last.query['status'], status);
        expect(api.last.query['page'], '1');
        expect(api.last.query['page_size'], '10');
      });
    }
  }

  test('reset visibility changes immediately even for a one-letter search',
      () async {
    await notifier.loadNasabah();
    expect(notifier.hasActiveFilters, isFalse);
    notifier.searchNasabah('b');
    expect((notifier.state as NasabahLoaded).hasActiveFilters, isTrue);
    notifier.searchNasabah('');
    expect((notifier.state as NasabahLoaded).hasActiveFilters, isFalse);
    await notifier.loadNasabah(); // cancels debounce before teardown
  });

  test('reset cancels pending search and discards later-page rows', () async {
    api.on('GET', _path,
        json: nasabahPage([nasabahRow('1')], count: 2, hasNext: true));
    await notifier.loadNasabah();
    api.on('GET', _path, json: nasabahPage([nasabahRow('2')], count: 2));
    await notifier.loadMoreNasabah();
    notifier.searchNasabah('obsolete');
    api.on('GET', _path, json: nasabahPage([nasabahRow('3')]));
    await notifier.resetFilters();
    final requestsAfterReset = api.requests.length;
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);

    expect(api.requests.length, requestsAfterReset);
    expect(
        (notifier.state as NasabahLoaded).nasabahList.map((n) => n.id), ['3']);
    expect((notifier.state as NasabahLoaded).currentPage, 1);
  });

  test('failed reset reload keeps reset controls and tab when retrying',
      () async {
    await notifier.loadNasabah();
    await notifier.setActiveTab(null);
    await notifier.setUrutan(NasabahUrutan.terbaru);
    api.on('GET', _path, status: 500, json: {'error': 'Gagal'});
    await notifier.resetFilters();
    expect(notifier.state, isA<NasabahError>());
    expect(notifier.hasActiveFilters, isFalse);
    expect(notifier.isActiveTab, isNull);
    api.on('GET', _path, json: nasabahPage([]));
    await notifier.loadNasabah();
    expect(api.last.query['status'], 'menunggu');
    expect(api.last.query['urutan'], 'nomor');
    expect((notifier.state as NasabahLoaded).nasabahList, isEmpty);
  });
}
