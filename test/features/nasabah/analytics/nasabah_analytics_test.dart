import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/analytics/nasabah_analytics.dart';

import '../../../support/fake_analytics_client.dart';

const _flow = '7c9819de-c44d-4fb3-acdf-b61d7d87174c';

void main() {
  late FakeAnalyticsClient client;

  setUp(() => client = FakeAnalyticsClient());

  Map<String, Object> last() => client.events.last.properties;

  test('a decision says which way and how long it took', () {
    nasabahDecided(client,
        approved: true, sinceOpened: const Duration(seconds: 12));
    nasabahDecided(client,
        approved: false, sinceOpened: const Duration(seconds: 3));

    expect(client.events.first.properties,
        {'keputusan': 'setuju', 'durasi_sejak_dibuka_detik': 12});
    expect(client.events.last.name, 'nasabah_pengajuan_diproses');
    expect(last()['keputusan'], 'tolak');
  });

  group('adding', () {
    late DateTime now;
    late NasabahAddAnalytics add;

    setUp(() {
      now = DateTime(2026, 11, 5, 9);
      add =
          NasabahAddAnalytics(client, clock: () => now, newFlowId: () => _flow);
    });

    test('opening starts a flow with its source', () {
      add.opened('dashboard');
      expect(client.events.single.name, 'nasabah_tambah_dimulai');
      expect(last(), {'alur_id': _flow, 'sumber': 'dashboard'});
    });

    test('a refusal names the fields and counts them', () {
      add.opened('halaman_nasabah');
      add.rejected(['nama', 'alamat']);
      expect(client.events.last.name, 'validasi_gagal');
      expect(last(), {
        'alur_id': _flow,
        'tugas': 'tambah_nasabah',
        'bidang': ['nama', 'alamat'],
        'jumlah_masalah': 2,
      });
    });

    test('a refusal with no known field says "lainnya"', () {
      add.opened('halaman_nasabah');
      add.rejected([]);
      expect(last()['bidang'], ['lainnya']);
      expect(last()['jumlah_masalah'], 1);
    });

    test('saving says how long it took and how many tries', () {
      add.opened('halaman_nasabah');
      add.submitTapped();
      add.submitTapped();
      now = now.add(const Duration(seconds: 80));
      add.saved();
      expect(client.events.last.name, 'nasabah_ditambah');
      expect(last(), {'alur_id': _flow, 'durasi_detik': 80, 'percobaan_ke': 2});
    });

    test('leaving without saving says how long and how many tries', () {
      add.opened('halaman_nasabah');
      add.submitTapped();
      now = now.add(const Duration(seconds: 40));

      add.closed();

      expect(client.events.last.name, 'nasabah_tambah_dibatalkan');
      expect(last(), {'alur_id': _flow, 'durasi_detik': 40, 'percobaan_ke': 1});
    });

    test('leaving without trying says so with zero attempts', () {
      add.opened('dashboard');

      add.closed();

      expect(last()['percobaan_ke'], 0);
    });

    test('a saved nasabah is not also a cancelled one', () {
      add.opened('dashboard');
      add.sending();
      add.saved();

      add.closed();

      expect(client.events.map((e) => e.name),
          ['nasabah_tambah_dimulai', 'nasabah_ditambah']);
    });

    test('a save that fails after the form closed is a cancellation', () {
      add.opened('dashboard');
      add.submitTapped();
      add.sending();
      add.closed();
      expect(client.events.map((e) => e.name), ['nasabah_tambah_dimulai']);

      add.sendFailed();

      expect(client.events.last.name, 'nasabah_tambah_dibatalkan');
    });
  });
}
