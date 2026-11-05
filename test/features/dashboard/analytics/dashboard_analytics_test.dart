import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/analytics/dashboard_analytics.dart';

import '../../../support/fake_analytics_client.dart';

void main() {
  late FakeAnalyticsClient client;

  setUp(() => client = FakeAnalyticsClient());

  test('a quick action says which button was pressed', () {
    dashboardQuickActionTapped(client, DashboardQuickAction.newTransaction);
    dashboardQuickActionTapped(client, DashboardQuickAction.addNasabah);

    expect(client.events.map((e) => e.name),
        ['dashboard_aksi_cepat_ditekan', 'dashboard_aksi_cepat_ditekan']);
    expect(client.events.map((e) => e.properties), [
      {'aksi': 'transaksi_baru'},
      {'aksi': 'tambah_nasabah'},
    ]);
  });

  test('a report range change says which range was chosen, never the dates',
      () {
    for (final choice in DashboardRangeChoice.values) {
      dashboardRangeChanged(client, choice);
    }

    expect(
        client.events.map((e) => e.name).toSet(), {'dashboard_periode_diubah'});
    expect(client.events.map((e) => e.properties['periode']),
        ['hari_ini', '7_hari', '30_hari', 'kustom']);
    expect(client.events.every((e) => e.properties.length == 1), isTrue);
  });

  test('a custom range says how long it is, in classes, not its dates', () {
    for (final days in [1, 7, 8, 30, 31]) {
      dashboardRangeChanged(client, DashboardRangeChoice.custom,
          customDays: days);
    }

    expect(client.events.map((e) => e.properties['lama_kustom_hari_kelas']),
        ['1_7_hari', '1_7_hari', '8_30_hari', '8_30_hari', 'lebih_30_hari']);
    expect(
        client.events.map((e) => e.properties['periode']).toSet(), {'kustom'});
  });

  test('the dashboard loading says how long it took and how many parts failed',
      () {
    dashboardLoaded(client,
        loadTime: const Duration(milliseconds: 2600), failedSections: 1);

    expect(client.events.single.name, 'dashboard_dimuat');
    expect(client.events.single.properties,
        {'durasi_muat_detik': 2, 'jumlah_bagian_gagal': 1});
  });
}
