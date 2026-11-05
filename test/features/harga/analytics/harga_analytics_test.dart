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

  test('a search says whether it found anything, never what was typed', () {
    hargaSearched(client, resultCount: 0);
    hargaSearched(client, resultCount: 3);

    expect(client.events.map((e) => e.name).toSet(), {'harga_dicari'});
    expect(client.events.map((e) => e.properties), [
      {'ada_hasil': false, 'jumlah_hasil_kelas': '0'},
      {'ada_hasil': true, 'jumlah_hasil_kelas': '1_5'},
    ]);
  });

  test('a search counts its results in classes, at every edge', () {
    for (final count in [0, 1, 5, 6, 20, 21]) {
      hargaSearched(client, resultCount: count);
    }

    expect(client.events.map((e) => e.properties['jumlah_hasil_kelas']),
        ['0', '1_5', '1_5', '6_20', '6_20', 'lebih_20']);
  });
}
