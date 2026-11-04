import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/analytics/nasabah_analytics.dart';

import '../../../support/fake_analytics_client.dart';

const _flow = '7c9819de-c44d-4fb3-acdf-b61d7d87174c';

void main() {
  late FakeAnalyticsClient client;

  setUp(() => client = FakeAnalyticsClient());

  Map<String, Object> last() => client.events.last.properties;

  group('search', () {
    test('names the tab and whether anything was found, not the text', () {
      nasabahSearched(client, activeTab: true, resultCount: 0);
      expect(client.events.single.name, 'nasabah_dicari');
      expect(last(), {
        'ada_hasil': false,
        'filter': 'aktif',
        'jumlah_hasil_kelas': '0',
      });
    });

    test('buckets the number of results and knows every tab', () {
      final seen = <(bool?, int), Map<String, Object>>{};
      for (final tab in [true, false, null]) {
        for (final count in [1, 5, 6, 20, 21]) {
          nasabahSearched(client, activeTab: tab, resultCount: count);
          seen[(tab, count)] = last();
        }
      }
      expect(
          [1, 5, 6, 20, 21].map((c) => seen[(true, c)]!['jumlah_hasil_kelas']),
          ['1_5', '1_5', '6_20', '6_20', 'lebih_20']);
      expect(seen[(false, 1)]!['filter'], 'tidak_aktif');
      expect(seen[(null, 1)]!['filter'], 'menunggu');
      expect(seen[(null, 1)]!['ada_hasil'], isTrue);
    });
  });

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

  test('invalid fields are named from what was typed', () {
    expect(
      nasabahInvalidFields(
          nama: ' ', kode: '', email: '', noHp: '', alamat: 'pendek'),
      ['nama', 'id_nasabah', 'email', 'no_hp', 'alamat'],
    );
    expect(
      nasabahInvalidFields(
          nama: 'A',
          kode: 'N1',
          email: 'a@x.test',
          noHp: '8123',
          alamat: 'Jl. Mawar No. 1'),
      isEmpty,
    );
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
  });
}
