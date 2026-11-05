import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';

import '../../../../support/fake_analytics_client.dart';
import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

void main() {
  late StubApi api;
  late NasabahNotifier notifier;
  late FakeAnalyticsClient analytics;
  NasabahEntity? chosen;

  setUp(() {
    api = StubApi();
    notifier = buildNasabahNotifier(api);
    analytics = FakeAnalyticsClient();
    chosen = null;
    api.on('GET', '/api/v1/nasabah',
        json: nasabahPage([
          nasabahRow('1', nama: 'Budi Santoso'),
          nasabahRow('2', nama: 'Budi Hartono'),
          nasabahRow('3', nama: 'Budiman'),
        ]));
  });

  Future<void> open(WidgetTester tester) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: PilihNasabahSection(
          selectedCustomer: null,
          onCustomerSelected: (n) => chosen = n,
        ),
      ),
      wrap: (app) => ProviderScope(
        overrides: [analyticsClientProvider.overrideWithValue(analytics)],
        child: withNasabahProvider(notifier, app),
      ),
      size: const Size(390, 844),
    );
    await tester.tap(find.text('Tap untuk pilih nasabah'));
    await tester.pumpAndSettle();
  }

  List<String> names() => analytics.events.map((e) => e.name).toList();

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('opening the picker without typing sends nothing',
      (tester) async {
    await open(tester);

    expect(analytics.events, isEmpty);
  });

  testWidgets('a search says it began and what it found, not what was typed',
      (tester) async {
    await open(tester);

    await search(tester, 'bud');

    expect(names(), ['pencarian_dimulai', 'pencarian_hasil']);
    expect(analytics.events.last.properties, {
      'alur_id': analytics.events.first.properties['alur_id'],
      'area': 'pemilih_nasabah',
      'jumlah_hasil_kelas': '1_5',
      'panjang_kueri_kelas': '3_5',
      'percobaan_ke': 1,
    });
    expect(analytics.events.toString(), isNot(contains('bud')));
  });

  testWidgets('choosing a row says where it was in the results',
      (tester) async {
    await open(tester);
    await search(tester, 'bud');

    await tester.tap(find.text('Budi Hartono'));
    await tester.pumpAndSettle();

    expect(chosen?.name, 'Budi Hartono');
    expect(names().last, 'pencarian_dipilih');
    expect(analytics.events.last.properties['posisi_hasil_kelas'], '2_3');
    expect(analytics.events.last.properties['percobaan_ke'], 1);
  });

  testWidgets('closing the picker after a search, without choosing, gives up',
      (tester) async {
    await open(tester);
    await search(tester, 'bud');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(names().last, 'pencarian_ditinggalkan');
    expect(analytics.events.last.properties['hasil_terakhir_kelas'], '1_5');
  });
}
