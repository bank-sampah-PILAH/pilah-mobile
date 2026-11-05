import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_range_filter.dart';

import '../../../../support/fake_analytics_client.dart';

void main() {
  late FakeAnalyticsClient client;

  setUp(() => client = FakeAnalyticsClient());

  List<String> names() => client.events.map((e) => e.name).toList();

  group('quick actions', () {
    Future<void> pumpButtons(WidgetTester tester) async {
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: DashboardActionButtons()),
          routes: [
            GoRoute(
              path: 'nasabah',
              builder: (_, __) => const Scaffold(body: Text('Daftar Nasabah')),
            ),
          ],
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [analyticsClientProvider.overrideWithValue(client)],
        child: MaterialApp.router(routerConfig: router),
      ));
    }

    testWidgets('Transaksi Baru is reported when pressed, once',
        (tester) async {
      await pumpButtons(tester);

      await tester.tap(find.text('Transaksi Baru'));
      await tester.pumpAndSettle();

      expect(names(), ['dashboard_aksi_cepat_ditekan']);
      expect(client.events.single.properties, {'aksi': 'transaksi_baru'});
    });

    testWidgets('Tambah Nasabah is reported when pressed, once',
        (tester) async {
      await pumpButtons(tester);

      await tester.tap(find.textContaining('Tambah'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
          names(), ['dashboard_aksi_cepat_ditekan', 'nasabah_tambah_dimulai']);
      expect(client.events.first.properties, {'aksi': 'tambah_nasabah'});
      expect(client.events.last.properties['sumber'], 'dashboard');
    });
  });

  group('report range', () {
    final today = DateUtils.dateOnly(DateTime.now());
    final june = DashboardReportRange(
        start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 30));

    Future<void> pumpFilter(
      WidgetTester tester, {
      DashboardReportRange? initial,
    }) async {
      var range = initial ?? june;
      await tester.pumpWidget(ProviderScope(
        overrides: [analyticsClientProvider.overrideWithValue(client)],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DashboardReportRangeFilter(
                range: range,
                onChanged: (value) => setState(() => range = value),
              ),
            ),
          ),
        ),
      ));
    }

    testWidgets('each preset names its range', (tester) async {
      await pumpFilter(tester);

      await tester.tap(find.text('7 Hari'));
      await tester.pump();
      await tester.tap(find.text('30 Hari'));
      await tester.pump();
      await tester.tap(find.text('Hari ini'));
      await tester.pump();

      expect(names(), List.filled(3, 'dashboard_periode_diubah'));
      expect(client.events.map((e) => e.properties['periode']),
          ['7_hari', '30_hari', 'hari_ini']);
    });

    testWidgets('pressing the range already shown is not a change',
        (tester) async {
      await pumpFilter(
        tester,
        initial: DashboardReportRange(
          start: DateTime(today.year, today.month, today.day - 6),
          end: today,
        ),
      );

      await tester.tap(find.text('7 Hari'));
      await tester.pump();

      expect(client.events, isEmpty);
    });

    testWidgets('applying a custom range is reported without its dates',
        (tester) async {
      await pumpFilter(tester);

      await tester.tap(find.text('Kustom'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('app-calendar-date-2026-06-20')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('app-calendar-date-2026-06-25')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(names(), ['dashboard_periode_diubah']);
      expect(client.events.single.properties,
          {'periode': 'kustom', 'lama_kustom_hari_kelas': '1_7_hari'});
    });

    testWidgets('opening or closing the calendar sends nothing',
        (tester) async {
      await pumpFilter(tester);

      await tester.tap(find.text('Kustom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kustom'));
      await tester.pumpAndSettle();

      expect(client.events, isEmpty);
    });
  });
}
