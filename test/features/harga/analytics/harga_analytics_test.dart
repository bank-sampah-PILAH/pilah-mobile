import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/analytics/harga_analytics.dart';

import '../../../support/fake_analytics_client.dart';

const _flow = '7c9819de-c44d-4fb3-acdf-b61d7d87174c';

void main() {
  late FakeAnalyticsClient client;
  late DateTime now;
  late HargaFormAnalytics form;

  setUp(() {
    client = FakeAnalyticsClient();
    now = DateTime(2026, 11, 5, 9);
    form = HargaFormAnalytics(client, clock: () => now, newFlowId: () => _flow);
  });

  Map<String, Object> last() => client.events.last.properties;

  test('opening the form for a new jenis starts a flow', () {
    form.opened(editing: false);

    expect(client.events.single.name, 'harga_form_dibuka');
    expect(last(), {'alur_id': _flow, 'mode': 'baru'});
  });

  test('opening the form for an existing jenis says it is a change', () {
    form.opened(editing: true);

    expect(last()['mode'], 'ubah');
  });

  test('a saved jenis says whether the price changed, never the price', () {
    form.opened(editing: true);
    now = now.add(const Duration(seconds: 45));
    form.submitTapped();
    form.submitTapped();

    form.saved(editing: true, priceChanged: true, category: 'plastik');

    expect(client.events.last.name, 'harga_disimpan');
    expect(last(), {
      'alur_id': _flow,
      'mode': 'ubah',
      'harga_berubah': true,
      'kategori': 'plastik',
      'percobaan_ke': 2,
      'durasi_detik': 45,
    });
  });

  test('a new jenis is saved with mode baru and no price change', () {
    form.opened(editing: false);
    form.submitTapped();

    form.saved(editing: false, priceChanged: false, category: 'dll');

    expect(last()['mode'], 'baru');
    expect(last()['harga_berubah'], false);
    expect(last()['kategori'], 'dll');
  });

  test('opening the form again starts a new flow and resets the attempts', () {
    form.opened(editing: false);
    form.submitTapped();
    form.opened(editing: true);
    form.submitTapped();

    form.saved(editing: true, priceChanged: false, category: 'kaca');

    expect(last()['percobaan_ke'], 1);
  });

  test('a save that arrives with no form ever opened sends nothing', () {
    form.saved(editing: true, priceChanged: false, category: 'kaca');

    expect(client.events, isEmpty);
  });

  test('a category outside the known list is sent as lainnya', () {
    form.opened(editing: false);

    form.saved(editing: false, priceChanged: false, category: 'Budi Santoso');

    expect(last()['kategori'], 'dll');
  });

  test('activating or deactivating says which, never which jenis', () {
    hargaStatusChanged(client, activated: true);
    hargaStatusChanged(client, activated: false);

    expect(client.events.map((e) => e.name).toSet(), {'harga_status_diubah'});
    expect(client.events.map((e) => e.properties), [
      {'aksi': 'aktifkan'},
      {'aksi': 'nonaktifkan'}
    ]);
  });

  test('opening the price history sends a bare event', () {
    hargaHistoryOpened(client);

    expect(client.events.single.name, 'harga_riwayat_dibuka');
    expect(client.events.single.properties, isEmpty);
  });

  group('leaving the form without saving', () {
    late int flows;
    late HargaFormAnalytics sequenced;

    setUp(() {
      flows = 0;
      sequenced = HargaFormAnalytics(client,
          clock: () => now, newFlowId: () => 'flow-${++flows}');
    });

    test('says how long it was open and how many times save was tried', () {
      sequenced.opened(editing: true);
      now = now.add(const Duration(seconds: 33));
      sequenced
        ..submitTapped()
        ..submitTapped();

      sequenced.closed();

      expect(client.events.last.name, 'harga_dibatalkan');
      expect(
          last(), {'alur_id': 'flow-1', 'durasi_detik': 33, 'percobaan_ke': 2});
    });

    test('leaving without trying says so with zero attempts', () {
      sequenced.opened(editing: false);

      sequenced.closed();

      expect(last()['percobaan_ke'], 0);
    });

    test('moving the panel to another row cancels the form of the first', () {
      sequenced.opened(editing: true);

      sequenced.opened(editing: true);

      expect(client.events.map((e) => e.name),
          ['harga_form_dibuka', 'harga_dibatalkan', 'harga_form_dibuka']);
      expect(client.events[1].properties['alur_id'], 'flow-1');
      expect(client.events[2].properties['alur_id'], 'flow-2');
    });

    test('a saved jenis is not also a cancelled one', () {
      sequenced.opened(editing: true);
      final flow = sequenced.sending();
      sequenced.saved(
          flow: flow, editing: true, priceChanged: false, category: 'kaca');

      sequenced.closed();

      expect(client.events.map((e) => e.name),
          ['harga_form_dibuka', 'harga_disimpan']);
    });

    test('changing the status of the jenis is not a cancelled form', () {
      sequenced.opened(editing: true);
      final flow = sequenced.sending();
      sequenced.finished(flow);

      sequenced.closed();

      expect(client.events.map((e) => e.name), ['harga_form_dibuka']);
    });

    test('a status change refused and then leaving is a cancellation', () {
      sequenced.opened(editing: true);
      final flow = sequenced.sending();
      sequenced.sendFailed(flow);

      sequenced.closed();

      expect(client.events.last.name, 'harga_dibatalkan');
    });

    test('a save that lands after the panel moved belongs to its own flow', () {
      sequenced.opened(editing: true);
      final first = sequenced.sending();
      sequenced.opened(editing: true);

      sequenced.saved(
          flow: first, editing: true, priceChanged: true, category: 'kaca');
      sequenced.closed();

      final saved =
          client.events.singleWhere((e) => e.name == 'harga_disimpan');
      expect(saved.properties['alur_id'], 'flow-1');
      final cancelled =
          client.events.where((e) => e.name == 'harga_dibatalkan').toList();
      expect(cancelled.map((e) => e.properties['alur_id']), ['flow-2']);
    });

    test('a save refused after the panel moved makes the first a cancellation',
        () {
      sequenced.opened(editing: true);
      final first = sequenced.sending();
      sequenced.opened(editing: true);
      expect(client.events.map((e) => e.name),
          ['harga_form_dibuka', 'harga_form_dibuka']);

      sequenced.sendFailed(first);

      final cancelled =
          client.events.where((e) => e.name == 'harga_dibatalkan').toList();
      expect(cancelled.map((e) => e.properties['alur_id']), ['flow-1']);
    });
  });
}
