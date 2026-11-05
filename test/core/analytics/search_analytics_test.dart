import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/search_analytics.dart';

import '../../support/fake_analytics_client.dart';

void main() {
  late FakeAnalyticsClient client;
  late DateTime now;
  late int flows;
  late SearchAnalytics search;

  setUp(() {
    client = FakeAnalyticsClient();
    now = DateTime(2026, 11, 5, 9);
    flows = 0;
    search = SearchAnalytics(
      client,
      area: 'nasabah',
      clock: () => now,
      newFlowId: () => 'flow-${++flows}',
    );
  });

  void after(int seconds) => now = now.add(Duration(seconds: seconds));

  List<String> names() => client.events.map((e) => e.name).toList();

  Map<String, Object> last() => client.events.last.properties;

  test('a query of one character is not a search', () {
    search.queryChanged('a');
    search.resultsSettled(query: 'a', count: 3);

    expect(client.events, isEmpty);
  });

  test('the first query of two characters starts a session', () {
    search.queryChanged('si');

    expect(names(), ['pencarian_dimulai']);
    expect(last(), {'alur_id': 'flow-1', 'area': 'nasabah'});
  });

  test('typing more of the same search does not start another session', () {
    search
      ..queryChanged('si')
      ..queryChanged('sit')
      ..queryChanged('siti');

    expect(names(), ['pencarian_dimulai']);
  });

  test('a settled query says how many results and how long the query was', () {
    search.queryChanged('sit');

    search.resultsSettled(query: 'sit', count: 3);

    expect(names().last, 'pencarian_hasil');
    expect(last(), {
      'alur_id': 'flow-1',
      'area': 'nasabah',
      'jumlah_hasil_kelas': '1_5',
      'panjang_kueri_kelas': '3_5',
      'percobaan_ke': 1,
    });
  });

  test('the tab it was searched in is reported when there is one', () {
    search.queryChanged('si');

    search.resultsSettled(query: 'si', count: 0, filter: 'aktif');

    expect(last()['filter'], 'aktif');
    expect(last()['jumlah_hasil_kelas'], '0');
    expect(last()['panjang_kueri_kelas'], '2');
  });

  test('result counts and query lengths are reported in classes', () {
    for (final (query, count) in [
      ('ab', 0),
      ('abc', 5),
      ('abcd', 6),
      ('abcdef', 20),
      ('abcdefg', 21),
    ]) {
      search.queryChanged(query);
      search.resultsSettled(query: query, count: count);
    }

    final results =
        client.events.where((e) => e.name == 'pencarian_hasil').toList();
    expect(results.map((e) => e.properties['jumlah_hasil_kelas']),
        ['0', '1_5', '6_20', '6_20', 'lebih_20']);
    expect(results.map((e) => e.properties['panjang_kueri_kelas']),
        ['2', '3_5', '3_5', 'lebih_5', 'lebih_5']);
  });

  test('the same settled query is not reported twice', () {
    search.queryChanged('si');
    search.resultsSettled(query: 'si', count: 3);
    search.resultsSettled(query: 'si', count: 3);

    expect(names(), ['pencarian_dimulai', 'pencarian_hasil']);
  });

  test('the same words in another tab are a new attempt', () {
    search.queryChanged('si');
    search.resultsSettled(query: 'si', count: 3, filter: 'aktif');
    search.resultsSettled(query: 'si', count: 0, filter: 'tidak_aktif');

    expect(names().where((n) => n == 'pencarian_hasil'), hasLength(2));
    expect(last()['percobaan_ke'], 2);
  });

  test('each refined query counts as another attempt', () {
    search.queryChanged('si');
    search.resultsSettled(query: 'si', count: 30);
    search.queryChanged('sit');
    search.resultsSettled(query: 'sit', count: 4);

    expect(last()['percobaan_ke'], 2);
  });

  test('choosing a row ends the session and says where it was in the list', () {
    search.queryChanged('sit');
    search.resultsSettled(query: 'sit', count: 12);
    after(9);

    search.picked(position: 3);

    expect(names().last, 'pencarian_dipilih');
    expect(last(), {
      'alur_id': 'flow-1',
      'area': 'nasabah',
      'posisi_hasil_kelas': '2_3',
      'percobaan_ke': 1,
      'durasi_detik': 9,
    });
  });

  test('the position of the chosen row is reported in classes', () {
    final positions = <String?>[];
    for (final position in [1, 2, 3, 4, 10, 11]) {
      search.queryChanged('si');
      search.resultsSettled(query: 'si', count: 50);
      search.picked(position: position);
      positions.add(last()['posisi_hasil_kelas'] as String?);
    }

    expect(positions, ['1', '2_3', '2_3', '4_10', '4_10', 'lebih_10']);
  });

  test('choosing before any result settled still counts the choice', () {
    search.queryChanged('si');

    search.picked(position: 1);

    expect(names().last, 'pencarian_dipilih');
    expect(last()['percobaan_ke'], 0);
  });

  test('typing again after a choice is a new session', () {
    search.queryChanged('si');
    search.resultsSettled(query: 'si', count: 3);
    search.picked(position: 1);

    search.queryChanged('bu');

    expect(names().last, 'pencarian_dimulai');
    expect(last()['alur_id'], 'flow-2');
  });

  test('clearing the query after results means the search was given up', () {
    search.queryChanged('si');
    search.resultsSettled(query: 'si', count: 0);
    after(14);

    search.queryChanged('');

    expect(names().last, 'pencarian_ditinggalkan');
    expect(last(), {
      'alur_id': 'flow-1',
      'area': 'nasabah',
      'percobaan_ke': 1,
      'hasil_terakhir_kelas': '0',
      'durasi_detik': 14,
    });
  });

  test('closing the search page without choosing is also giving up', () {
    search.queryChanged('si');
    search.resultsSettled(query: 'si', count: 25);

    search.closed();

    expect(names().last, 'pencarian_ditinggalkan');
    expect(last()['hasil_terakhir_kelas'], 'lebih_20');
  });

  test('a search that never showed a result is not reported as given up', () {
    search.queryChanged('si');

    search.closed();

    expect(names(), ['pencarian_dimulai']);
  });

  test('a session that already ended is not ended a second time', () {
    search.queryChanged('si');
    search.resultsSettled(query: 'si', count: 3);
    search.picked(position: 1);

    search.closed();
    search.queryChanged('');

    expect(names().where((n) => n == 'pencarian_ditinggalkan'), isEmpty);
  });

  test('choosing with no session open sends nothing', () {
    search.picked(position: 1);

    expect(client.events, isEmpty);
  });

  test('a settled query with no typing before it still opens the session', () {
    search.resultsSettled(query: 'sit', count: 2);

    expect(names(), ['pencarian_dimulai', 'pencarian_hasil']);
  });

  test('the typed words never leave the app', () {
    search.queryChanged('Siti Aminah');
    search.resultsSettled(query: 'Siti Aminah', count: 1);
    search.picked(position: 1);

    expect(client.events.toString(), isNot(contains('Siti')));
    expect(client.events.toString(), isNot(contains('Aminah')));
  });
}
