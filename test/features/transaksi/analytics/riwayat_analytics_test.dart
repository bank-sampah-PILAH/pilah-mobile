import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/analytics/riwayat_analytics.dart';

import '../../../support/fake_analytics_client.dart';

void main() {
  late FakeAnalyticsClient client;
  setUp(() => client = FakeAnalyticsClient());

  Map<String, Object> last() => client.events.last.properties;

  test('a filter change names the kind of filter and its class of value', () {
    riwayatFilterChanged(client, RiwayatFilterKind.periode, value: 'hari_ini');

    expect(client.events.last.name, 'riwayat_filter_diubah');
    expect(last(), {'jenis_filter': 'periode', 'nilai_kelas': 'hari_ini'});
  });

  test('a search or a reset has no value to send', () {
    riwayatFilterChanged(client, RiwayatFilterKind.pencarian);
    expect(last(), {'jenis_filter': 'pencarian'});

    riwayatFilterChanged(client, RiwayatFilterKind.reset);
    expect(last(), {'jenis_filter': 'reset'});
  });

  test('opening a detail says what kind of activity it was', () {
    riwayatDetailOpened(client, 'setoran');

    expect(client.events.last.name, 'riwayat_detail_dibuka');
    expect(last(), {'jenis_aktivitas': 'setoran'});
  });

  test('an export says whether it worked', () {
    riwayatExported(client, success: false);

    expect(client.events.last.name, 'riwayat_diekspor');
    expect(last(), {'format': 'xlsx', 'berhasil': false});
  });

  test('voiding none says nothing', () {
    riwayatSetoranVoided(client, count: 0, bulk: true);

    expect(client.events, isEmpty);
  });

  test('voiding says how many setoran, and one by one or several at once', () {
    riwayatSetoranVoided(client, count: 3, bulk: true);
    expect(client.events.last.name, 'riwayat_setoran_dibatalkan');
    expect(last(), {'cara': 'massal', 'jumlah_setoran': 3});

    riwayatSetoranVoided(client, count: 1, bulk: false);
    expect(last(), {'cara': 'satuan', 'jumlah_setoran': 1});
  });
}
