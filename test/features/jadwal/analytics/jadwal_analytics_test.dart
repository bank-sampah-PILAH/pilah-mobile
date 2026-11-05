import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/analytics/jadwal_analytics.dart';

import '../../../support/fake_analytics_client.dart';

const _flow = '7c9819de-c44d-4fb3-acdf-b61d7d87174c';

void main() {
  late FakeAnalyticsClient client;
  late DateTime now;
  late JadwalFormAnalytics form;

  setUp(() {
    client = FakeAnalyticsClient();
    now = DateTime(2026, 11, 3, 9);
    form =
        JadwalFormAnalytics(client, clock: () => now, newFlowId: () => _flow);
  });

  Map<String, Object> last() => client.events.last.properties;

  test('opening a new schedule starts a flow', () {
    form.opened(editing: false);

    expect(client.events.single.name, 'jadwal_form_dibuka');
    expect(last(), {'alur_id': _flow, 'mode': 'baru'});
  });

  test('opening an existing schedule says it is a change', () {
    form.opened(editing: true);

    expect(last()['mode'], 'ubah');
  });

  test('a created schedule says its kind, who it is for and how far away', () {
    form.opened(editing: false);
    now = now.add(const Duration(seconds: 70));
    form.submitTapped();

    form.saved(
      editing: false,
      activity: 'penimbangan',
      audience: 'semua_nasabah',
      startsAt: DateTime(2026, 11, 5, 9),
      endsAt: DateTime(2026, 11, 5, 11),
    );

    expect(client.events.last.name, 'jadwal_dibuat');
    expect(last(), {
      'alur_id': _flow,
      'jenis': 'penimbangan',
      'cakupan': 'semua',
      'durasi_detik': 70,
      'percobaan_ke': 1,
      'jeda_hari_kelas': '1_7_hari',
      'lama_kegiatan_kelas': '1_3_jam',
    });
  });

  test('a schedule for chosen nasabah is not for everyone', () {
    form.opened(editing: false);

    form.saved(
      editing: false,
      activity: 'pencairan',
      audience: 'nasabah_terpilih',
      startsAt: DateTime(2026, 11, 3, 15),
      endsAt: DateTime(2026, 11, 3, 15, 30),
    );

    expect(last()['cakupan'], 'terpilih');
    expect(last()['jeda_hari_kelas'], 'hari_ini');
    expect(last()['lama_kegiatan_kelas'], 'kurang_1_jam');
  });

  test('a schedule far ahead and long is told apart', () {
    form.opened(editing: false);

    form.saved(
      editing: false,
      activity: 'penimbangan',
      audience: 'semua_nasabah',
      startsAt: DateTime(2026, 12, 1, 8),
      endsAt: DateTime(2026, 12, 1, 14),
    );

    expect(last()['jeda_hari_kelas'], 'lebih_7_hari');
    expect(last()['lama_kegiatan_kelas'], 'lebih_3_jam');
  });

  test('a changed schedule is reported as a change, not a new one', () {
    form.opened(editing: true);

    form.saved(
      editing: true,
      activity: 'penimbangan',
      audience: 'semua_nasabah',
      startsAt: DateTime(2026, 11, 5, 9),
      endsAt: DateTime(2026, 11, 5, 10),
    );

    expect(client.events.last.name, 'jadwal_diubah');
  });

  test('a refused form says why, by a fixed name', () {
    form.opened(editing: false);

    form.rejected(JadwalProblem.startInPast);
    form.rejected(JadwalProblem.endBeforeStart);
    form.rejected(JadwalProblem.requiredFieldEmpty);

    final problems = client.events
        .where((e) => e.name == 'validasi_gagal')
        .map((e) => e.properties['masalah'])
        .toList();
    expect(problems, [
      ['waktu_mulai_lampau'],
      ['waktu_selesai_sebelum_mulai'],
      ['bidang_wajib_kosong'],
    ]);
    expect(client.events.last.properties['tugas'], 'jadwal');
  });

  test('pressing save counts the attempts', () {
    form.opened(editing: false);

    form
      ..submitTapped()
      ..submitTapped();
    form.saved(
      editing: false,
      activity: 'penimbangan',
      audience: 'semua_nasabah',
      startsAt: DateTime(2026, 11, 4, 9),
      endsAt: DateTime(2026, 11, 4, 10),
    );

    expect(last()['percobaan_ke'], 2);
  });

  test('nothing is sent about a form that was never opened', () {
    form.rejected(JadwalProblem.startInPast);

    expect(client.log, isEmpty);
  });

  test('changing a status says which action and from which status', () {
    jadwalStatusChanged(client, action: 'terbitkan', statusBefore: 'draft');

    expect(client.events.single.name, 'jadwal_status_diubah');
    expect(last(), {'aksi': 'terbitkan', 'status_sebelumnya': 'draft'});
  });

  group('leaving the form without saving', () {
    test('says how long it was open and how many times save was tried', () {
      form.opened(editing: false);
      now = now.add(const Duration(seconds: 25));
      form
        ..submitTapped()
        ..submitTapped();

      form.closed();

      expect(client.events.last.name, 'jadwal_dibatalkan');
      expect(last(), {'alur_id': _flow, 'durasi_detik': 25, 'percobaan_ke': 2});
    });

    test('leaving without trying says so with zero attempts', () {
      form.opened(editing: true);

      form.closed();

      expect(last()['percobaan_ke'], 0);
    });

    test('a saved schedule is not also a cancelled one', () {
      form.opened(editing: false);
      form.sending();
      form.saved(
        editing: false,
        activity: 'penimbangan',
        audience: 'semua_nasabah',
        startsAt: now.add(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 1, hours: 2)),
      );

      form.closed();

      expect(client.events.map((e) => e.name),
          ['jadwal_form_dibuka', 'jadwal_dibuat']);
    });

    test('a refused save followed by leaving is a cancellation', () {
      form.opened(editing: false);
      form
        ..submitTapped()
        ..sending()
        ..sendFailed();

      form.closed();

      expect(client.events.last.name, 'jadwal_dibatalkan');
      expect(last()['percobaan_ke'], 1);
    });
  });
}
