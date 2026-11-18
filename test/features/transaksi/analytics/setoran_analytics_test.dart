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

  test('finishing without sending the message is its own action', () {
    setoran.started();

    setoran.finishedWithoutMessage();

    expect(client.events.last.name, 'setoran_aksi_sesudah_simpan');
    expect(last()['aksi'], 'selesai');
    expect(last().containsKey('berhasil'), isFalse);
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
        'jumlah_item_ditambah': 0,
        'jumlah_item_dihapus': 0,
        'jumlah_item_diubah_jenis': 0,
        'jumlah_item_diubah_berat': 0,
      });
    });

    test('a saved edit says what kind of change was made to the items', () {
      edit.started();

      edit.saved(
        itemCount: 3,
        itemsChanged: true,
        noteChanged: false,
        changes: const ItemChangeCounts(
          added: 1,
          removed: 2,
          jenisChanged: 3,
          beratChanged: 4,
        ),
      );

      expect(last()['jumlah_item_ditambah'], 1);
      expect(last()['jumlah_item_dihapus'], 2);
      expect(last()['jumlah_item_diubah_jenis'], 3);
      expect(last()['jumlah_item_diubah_berat'], 4);
    });

    test('how long after the setoran was made is told in classes', () {
      final seen = <Object?>[];
      for (final days in [0, 1, 7, 8, 40]) {
        edit
          ..started()
          ..saved(
            itemCount: 1,
            itemsChanged: true,
            noteChanged: false,
            recordedAt: now.subtract(Duration(days: days)),
          );
        seen.add(last()['jeda_sejak_dibuat_hari_kelas']);
      }

      expect(seen,
          ['hari_ini', '1_7_hari', '1_7_hari', 'lebih_7_hari', 'lebih_7_hari']);
    });

    test('when it is not known how old the setoran is, nothing is said', () {
      edit
        ..started()
        ..saved(itemCount: 1, itemsChanged: true, noteChanged: false);

      expect(last().containsKey('jeda_sejak_dibuat_hari_kelas'), isFalse);
    });

    test('closing the sheet without saving is reported once, with its time',
        () {
      edit.started();
      after(30);

      edit
        ..closed()
        ..closed();

      expect(client.events.map((e) => e.name),
          ['setoran_ubah_dimulai', 'setoran_ubah_dibatalkan']);
      expect(last(), {'alur_id': _flow, 'durasi_detik': 30});
    });

    test('closing the sheet after a save is not a cancellation', () {
      edit
        ..started()
        ..saved(itemCount: 1, itemsChanged: true, noteChanged: false)
        ..closed();

      expect(client.events.map((e) => e.name),
          ['setoran_ubah_dimulai', 'setoran_diubah']);
    });

    test('a sheet that was never opened has nothing to cancel', () {
      edit.closed();

      expect(client.events, isEmpty);
    });

    test('a changed note is named too', () {
      edit.started();

      edit.saved(itemCount: 1, itemsChanged: true, noteChanged: true);

      expect(last()['bidang_diubah'], ['item', 'catatan']);
    });
  });

  group('filling in the items', () {
    List<Map<String, Object>> filled() => [
          for (final e in client.events)
            if (e.name == 'setoran_item_diisi') e.properties,
        ];

    test('the first item that gets filled is item 1 of the flow', () {
      setoran.started();

      setoran.itemFilled('baris-1');

      expect(filled(), [
        {'alur_id': _flow, 'item_ke': 1},
      ]);
    });

    test('each later item that gets filled counts on', () {
      setoran.started();

      setoran
        ..itemFilled('baris-1')
        ..itemFilled('baris-2')
        ..itemFilled('baris-3');

      expect(filled().map((p) => p['item_ke']), [1, 2, 3]);
    });

    test('editing an item that was already counted sends nothing more', () {
      setoran.started();

      setoran
        ..itemFilled('baris-1')
        ..itemFilled('baris-1')
        ..itemFilled('baris-1');

      expect(filled(), hasLength(1));
    });

    test('a new flow counts from 1 again', () {
      setoran
        ..started()
        ..itemFilled('baris-1')
        ..itemFilled('baris-2')
        ..started()
        ..itemFilled('baris-1');

      expect(filled().map((p) => p['item_ke']), [1, 2, 1]);
    });

    test('before the form is opened there is no flow, so nothing is sent', () {
      setoran.itemFilled('baris-1');

      expect(client.events, isEmpty);
    });

    test('it names neither the jenis nor the weight', () {
      setoran.started();

      setoran.itemFilled('baris-1');

      expect(filled().single.keys.toSet(), {'alur_id', 'item_ke'});
    });
  });

  group('counting what kind of change an edit made to the items', () {
    test('nothing changed, nothing counted', () {
      final counts = ItemChangeCounts.between(
        before: [(jenisSampahId: 'j1', berat: 2.0)],
        after: [(origin: 0, jenisSampahId: 'j1', berat: 2.0)],
      );

      expect((
        counts.added,
        counts.removed,
        counts.jenisChanged,
        counts.beratChanged
      ), (
        0,
        0,
        0,
        0
      ));
    });

    test('a new row is added, a missing row is removed', () {
      final counts = ItemChangeCounts.between(
        before: [
          (jenisSampahId: 'j1', berat: 2.0),
          (jenisSampahId: 'j2', berat: 1.0),
        ],
        after: [
          (origin: 0, jenisSampahId: 'j1', berat: 2.0),
          (origin: null, jenisSampahId: 'j3', berat: 5.0),
        ],
      );

      expect(counts.added, 1);
      expect(counts.removed, 1);
      expect(counts.jenisChanged, 0);
      expect(counts.beratChanged, 0);
    });

    test('a row whose jenis changed is not a removal and an addition', () {
      final counts = ItemChangeCounts.between(
        before: [(jenisSampahId: 'j1', berat: 2.0)],
        after: [(origin: 0, jenisSampahId: 'j2', berat: 2.0)],
      );

      expect(counts.jenisChanged, 1);
      expect(counts.added, 0);
      expect(counts.removed, 0);
      expect(counts.beratChanged, 0);
    });

    test('a row changed in both ways counts in both', () {
      final counts = ItemChangeCounts.between(
        before: [(jenisSampahId: 'j1', berat: 2.0)],
        after: [(origin: 0, jenisSampahId: 'j2', berat: 3.5)],
      );

      expect(counts.jenisChanged, 1);
      expect(counts.beratChanged, 1);
    });

    test('a row that was blanked counts as a change of jenis only when set',
        () {
      final counts = ItemChangeCounts.between(
        before: [(jenisSampahId: 'j1', berat: 2.0)],
        after: [(origin: 0, jenisSampahId: null, berat: 2.0)],
      );

      expect(counts.jenisChanged, 1);
    });
  });
}
