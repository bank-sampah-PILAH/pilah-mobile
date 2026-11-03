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
        client.events.map((e) => e.name).toSet(), {'dashboard_rentang_diubah'});
    expect(client.events.map((e) => e.properties['periode']),
        ['1_hari', '7_hari', '30_hari', 'kustom']);
    expect(client.events.every((e) => e.properties.length == 1), isTrue);
  });
}
