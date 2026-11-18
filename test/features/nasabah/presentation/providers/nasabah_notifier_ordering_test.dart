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

  for (final (order, parameter) in [
    (NasabahUrutan.nomor, 'nomor'),
    (NasabahUrutan.nama, 'nama'),
    (NasabahUrutan.terbaru, 'terbaru'),
    (NasabahUrutan.saldoTerbesar, 'saldo_terbesar'),
    (NasabahUrutan.saldoTerkecil, 'saldo_terkecil'),
  ]) {
    test('choosing $parameter sends ordering through the complete HTTP stack',
        () async {
      await notifier.loadNasabah();
      await notifier.setUrutan(order);

      expect(api.last.query['urutan'], parameter);
      expect(api.last.query['page'], '1');
      expect(notifier.urutan, order);
      expect((notifier.state as NasabahLoaded).urutan, order);
    });
  }

  test('search and all status tabs preserve the selected order', () async {
    await notifier.loadNasabah();
    await notifier.setUrutan(NasabahUrutan.saldoTerbesar);
    notifier.searchNasabah('budi');
    await Future<void>.delayed(NasabahNotifier.jedaPencarian * 2);
    expect(api.last.query['search'], 'budi');
    expect(api.last.query['urutan'], 'saldo_terbesar');
    for (final (tab, parameter) in [
      (false, 'tidak_aktif'),
      (null, 'menunggu'),
      (true, 'aktif')
    ]) {
      await notifier.setActiveTab(tab);
      expect(api.last.query['status'], parameter);
      expect(api.last.query['urutan'], 'saldo_terbesar');
      expect(api.last.query['search'], 'budi');
      expect(api.last.query['page'], '1');
    }
  });

  test('scroll and numbered pages retain order; changing order replaces rows',
      () async {
    api.on('GET', _path,
        json: nasabahPage([nasabahRow('1')], count: 3, hasNext: true));
    await notifier.loadNasabah(pageSize: 1);
    await notifier.setUrutan(NasabahUrutan.nama);
    api.on('GET', _path,
        json: nasabahPage([nasabahRow('2')], count: 3, hasNext: true));
    await notifier.loadMoreNasabah();
    expect(api.last.query['page'], '2');
    expect(api.last.query['urutan'], 'nama');
    expect((notifier.state as NasabahLoaded).nasabahList.map((n) => n.id),
        ['1', '2']);

    api.on('GET', _path, json: nasabahPage([nasabahRow('3')], count: 3));
    await notifier.loadPage(3);
    expect(api.last.query['page'], '3');
    expect(api.last.query['urutan'], 'nama');
    await notifier.setUrutan(NasabahUrutan.terbaru);
    expect(api.last.query['page'], '1');
    expect(api.last.query['urutan'], 'terbaru');
    expect(
        (notifier.state as NasabahLoaded).nasabahList.map((n) => n.id), ['3']);
  });

  test('failed ordering request preserves selection for retry', () async {
    await notifier.loadNasabah();
    api.on('GET', _path, status: 500, json: {'error': 'Gagal'});
    await notifier.setUrutan(NasabahUrutan.saldoTerkecil);
    expect(notifier.state, isA<NasabahError>());
    expect(notifier.urutan, NasabahUrutan.saldoTerkecil);
    api.on('GET', _path, json: nasabahPage([]));
    await notifier.loadNasabah();
    expect(api.last.query['urutan'], 'saldo_terkecil');
    expect((notifier.state as NasabahLoaded).nasabahList, isEmpty);
  });

  test('logout restores default ordering', () async {
    await notifier.loadNasabah();
    await notifier.setUrutan(NasabahUrutan.nama);
    notifier.reset();
    expect(notifier.urutan, NasabahUrutan.nomor);
    expect(notifier.state, isA<NasabahInitial>());
  });
}
