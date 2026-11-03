import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/analytics/setoran_analytics.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/setoran_draft.dart';

import '../../../support/fake_analytics_client.dart';

const _flow = '7c9819de-c44d-4fb3-acdf-b61d7d87174c';

void main() {
  late FakeAnalyticsClient client;
  late DateTime now;
  late SetoranAnalytics setoran;

  setUp(() {
    client = FakeAnalyticsClient();
    now = DateTime(2026, 11, 3, 9);
    setoran =
        SetoranAnalytics(client, clock: () => now, newFlowId: () => _flow);
  });

  void after(int seconds) => now = now.add(Duration(seconds: seconds));

  Map<String, Object> last() => client.events.last.properties;

  test('opening the form starts a flow', () {
    setoran.started();

    expect(client.events.single.name, 'setoran_dimulai');
    expect(last(), {'alur_id': _flow});
  });

  test('every event of one flow carries the same flow id', () {
    setoran
      ..started()
      ..nasabahChosen()
      ..saveTapped(itemCount: 2)
      ..validationFailed({SetoranProblem.noItems});

    expect(client.events.map((e) => e.properties['alur_id']).toSet(), {_flow});
  });

  test('choosing a nasabah says how long it took since the last step', () {
    setoran.started();
    after(20);

    setoran.nasabahChosen();

    expect(client.events.last.name, 'setoran_nasabah_dipilih');
    expect(last()['durasi_langkah_detik'], 20);
  });

  test('pressing save counts the attempts', () {
    setoran.started();

    setoran.saveTapped(itemCount: 2);
    setoran.saveTapped(itemCount: 2);

    final taps =
        client.events.where((e) => e.name == 'setoran_simpan_ditekan').toList();
    expect(taps.map((e) => e.properties['percobaan_ke']), [1, 2]);
    expect(taps.first.properties['jumlah_item'], 2);
  });

  test('a rejected form lists the problems by their fixed names', () {
    setoran.started();

    setoran.validationFailed({
      SetoranProblem.noNasabah,
      SetoranProblem.itemWithoutJenis,
      SetoranProblem.nonPositiveBerat,
    });

    expect(client.events.last.name, 'validasi_gagal');
    expect(last()['tugas'], 'setoran');
    expect(last()['masalah'],
        ['nasabah_belum_dipilih', 'item_tanpa_jenis', 'berat_nol']);
    expect(last()['jumlah_masalah'], 3);
  });

  test('an empty list is named belum_ada_item', () {
    setoran.started();

    setoran.validationFailed({SetoranProblem.noItems});

    expect(last()['masalah'], ['belum_ada_item']);
  });

  test('a saved setoran says what it held and how long it took', () {
    setoran.started();
    setoran.saveTapped(itemCount: 3);
    after(95);

    setoran.saved(itemCount: 3, distinctJenis: 3, totalKg: 7.26);

    expect(client.events.last.name, 'setoran_disimpan');
    expect(last(), {
      'alur_id': _flow,
      'jumlah_item': 3,
      'jumlah_jenis_berbeda': 3,
      'berat_total_kg': 7.3,
      'durasi_detik': 95,
      'percobaan_ke': 1,
    });
  });

  test('after saving, it says whether WhatsApp opened and a template was used',
      () {
    setoran.started();

    setoran.afterSave(opened: true, templateUsed: false);

    expect(client.events.last.name, 'setoran_aksi_sesudah_simpan');
    expect(last()['aksi'], 'kirim_wa');
    expect(last()['berhasil'], true);
    expect(last()['template_wa_dipakai'], false);
  });

  test('leaving before saving says where the pengurus stopped', () {
    setoran.started();
    after(40);

    setoran.leftWithoutSaving(SetoranStep.item);

    expect(client.events.last.name, 'setoran_dibatalkan');
    expect(last()['langkah_terakhir'], 'item');
    expect(last()['durasi_detik'], 40);
  });

  test('every step has a fixed name', () {
    expect(SetoranStep.values.map((s) => s.name),
        ['nasabah', 'item', 'siap_simpan']);
  });

  test('leaving after saving is not a cancellation', () {
    setoran.started();
    setoran.saved(itemCount: 1, distinctJenis: 1, totalKg: 1);
    client.log.clear();

    setoran.leftWithoutSaving(SetoranStep.siapSimpan);

    expect(client.log, isEmpty);
  });

  test('nothing is sent about a flow that never started', () {
    setoran.leftWithoutSaving(SetoranStep.nasabah);

    expect(client.log, isEmpty);
  });

  group('editing a recorded setoran', () {
    late SetoranEditAnalytics edit;

    setUp(() {
      edit = SetoranEditAnalytics(client,
          clock: () => now, newFlowId: () => _flow);
    });

    test('opening the sheet starts a flow', () {
      edit.started();

      expect(client.events.single.name, 'setoran_ubah_dimulai');
      expect(last(), {'alur_id': _flow});
    });

    test('a saved edit says what changed and how long it took', () {
      edit.started();
      after(50);

      edit.saved(itemCount: 2, itemsChanged: true, noteChanged: false);

      expect(client.events.last.name, 'setoran_diubah');
      expect(last(), {
        'alur_id': _flow,
        'jumlah_item': 2,
        'bidang_diubah': ['item'],
        'durasi_detik': 50,
      });
    });

    test('a changed note is named too', () {
      edit.started();

      edit.saved(itemCount: 1, itemsChanged: true, noteChanged: true);

      expect(last()['bidang_diubah'], ['item', 'catatan']);
    });
  });
}
