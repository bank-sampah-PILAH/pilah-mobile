import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

import '../../../../support/fake_analytics_client.dart';
import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

void main() {
  late StubApi api;
  late NasabahNotifier notifier;
  late FakeAnalyticsClient analytics;

  setUp(() {
    analytics = FakeAnalyticsClient();
    api = StubApi();
    notifier = buildNasabahNotifier(api);
  });

  Future<void> open(WidgetTester tester) async {
    await pumpRouted(
      tester,
      // A non-const instance so the constructor itself runs.
      // ignore: prefer_const_constructors
      NasabahPage(),
      wrap: (app) => withNasabahProvider(notifier, app, analytics: analytics),
      size: const Size(590, 2000),
    );
    await tester.pumpAndSettle();
  }

  void listAs(List<Map<String, dynamic>> rows, {String? status}) {
    api.on('GET', _path, json: nasabahPage(rows));
  }

  testWidgets('lists the active nasabah', (tester) async {
    listAs([
      nasabahRow('1'),
      nasabahRow('2', nama: 'Siti Aminah', active: false),
    ]);
    await open(tester);

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
  });

  testWidgets('each tab shows its own empty state', (tester) async {
    listAs([]);
    await open(tester);
    expect(find.text('Belum Ada Nasabah'), findsOneWidget);

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak Ada Nasabah Nonaktif'), findsOneWidget);
    expect(api.last.query['status'], 'tidak_aktif');

    await tester.tap(find.text('Menunggu').first);
    await tester.pumpAndSettle();
    expect(find.text('Tidak Ada Pengajuan'), findsOneWidget);
    expect(api.last.query['status'], 'menunggu');

    await tester.tap(find.text('Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Belum Ada Nasabah'), findsOneWidget);
  });

  testWidgets('searching asks the server and explains an empty result',
      (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);

    listAs([]);
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    expect(api.last.query['search'], 'zzz');
    expect(find.text('Nasabah Tidak Ditemukan'), findsOneWidget);
    // The session says what it found, and nothing of what was typed.
    expect(analytics.events.map((e) => e.name),
        ['pencarian_dimulai', 'pencarian_hasil']);
    expect(analytics.events.last.properties, {
      'alur_id': analytics.events.first.properties['alur_id'],
      'area': 'nasabah',
      'jumlah_hasil_kelas': '0',
      'panjang_kueri_kelas': '3_5',
      'percobaan_ke': 1,
      'filter': 'aktif',
    });
    expect(analytics.events.toString(), isNot(contains('zzz')));
  });

  testWidgets('loading the same search again in another order is not new',
      (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'budi');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();
    expect(analytics.events.where((e) => e.name == 'pencarian_hasil'),
        hasLength(1));

    // Another order loads the same search again, through a reloading state.
    final before = api.requests.length;
    await tester.tap(find.text('Nomor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nama A–Z').last);
    await tester.pumpAndSettle();

    expect(api.requests.length, greaterThan(before),
        reason: 'the new order reloaded the list');
    expect(analytics.events.where((e) => e.name == 'pencarian_hasil'),
        hasLength(1));
  });

  testWidgets('leaving the list ends the search, and coming back is a new one',
      (tester) async {
    listAs([nasabahRow('1')]);
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    await pumpRouted(
      tester,
      // ignore: prefer_const_constructors
      NasabahPage(),
      // The shell keeps the list of a tab that is not shown, with its tickers
      // off.
      wrap: (app) => ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (_, on, __) => TickerMode(
          enabled: on,
          child: withNasabahProvider(notifier, app, analytics: analytics),
        ),
      ),
      size: const Size(590, 2000),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'budi');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();
    final firstFlow = analytics.events.first.properties['alur_id'];

    shown.value = false;
    await tester.pump();
    expect(analytics.events.last.name, 'pencarian_ditinggalkan');

    shown.value = true;
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'budis');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    final again =
        analytics.events.lastWhere((e) => e.name == 'pencarian_hasil');
    expect(again.properties['percobaan_ke'], 1);
    expect(again.properties['alur_id'], isNot(firstFlow));
  });

  testWidgets('a one-letter search is not reported', (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);

    await tester.enterText(find.byType(TextField).first, 'z');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    expect(
        analytics.events.where((e) => e.name.startsWith('pencarian')), isEmpty);
  });

  testWidgets('the same words in another tab are another attempt',
      (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'budi');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pumpAndSettle();

    final results =
        analytics.events.where((e) => e.name == 'pencarian_hasil').toList();
    expect(results, hasLength(2));
    expect(results.last.properties['filter'], 'tidak_aktif');
    expect(results.last.properties['percobaan_ke'], 2);
  });

  testWidgets('opening a nasabah from the results ends the search',
      (tester) async {
    listAs([nasabahRow('1'), nasabahRow('2', nama: 'Budi Hartono')]);
    api.on('GET', '$_path/2', json: <String, dynamic>{});
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'budi');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Budi Hartono'));
    await tester.pumpAndSettle();

    expect(analytics.events.last.name, 'pencarian_dipilih');
    expect(analytics.events.last.properties['posisi_hasil_kelas'], '2_3');
    expect(analytics.events.last.properties['area'], 'nasabah');
  });

  testWidgets('the list loading again after a pick does not start a session',
      (tester) async {
    listAs([nasabahRow('1'), nasabahRow('2', nama: 'Budi Hartono')]);
    api.on('GET', '$_path/2', json: <String, dynamic>{});
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'budi');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi Hartono'));
    await tester.pumpAndSettle();
    final sent = analytics.events.length;

    // The list comes back from the detail and loads the same search again.
    final reload = notifier.loadNasabah();
    await tester.pumpAndSettle();
    await reload;

    expect(analytics.events.length, sent);
  });

  testWidgets('clearing the words after results means giving up',
      (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'budi');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    expect(analytics.events.map((e) => e.name),
        contains('pencarian_ditinggalkan'));
  });

  testWidgets('closing the add form without saving is reported',
      (tester) async {
    listAs([]);
    await open(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(analytics.events.map((e) => e.name),
        ['nasabah_tambah_dimulai', 'nasabah_tambah_dibatalkan']);
    expect(analytics.events.last.properties['percobaan_ke'], 0);
  });

  testWidgets('the add button on the page says where the form came from',
      (tester) async {
    listAs([]);
    await open(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final opened =
        analytics.events.where((e) => e.name == 'nasabah_tambah_dimulai');
    expect(opened.single.properties['sumber'], 'halaman_nasabah');
  });

  testWidgets('a failed load can be retried by pulling down', (tester) async {
    api.on('GET', _path, status: 500, json: {});
    await open(tester);
    expect(find.text('Gagal Memuat Data'), findsOneWidget);

    listAs([nasabahRow('1')]);
    await tester.drag(find.byType(EmptyView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('pull-to-refresh fetches the current nasabah balance', (
    tester,
  ) async {
    listAs([nasabahRow('1', saldo: '25000')]);
    await open(tester);
    expect(find.text('Rp 25.000'), findsOneWidget);

    listAs([nasabahRow('1', saldo: '30000')]);
    await tester.drag(find.byType(ListView).first, const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Rp 30.000'), findsOneWidget);
    expect(
      api.requests
          .where((request) => request.method == 'GET' && request.path == _path),
      hasLength(2),
    );
  });

  testWidgets('the add button opens the form', (tester) async {
    listAs([]);
    await open(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TambahNasabahBottomSheet), findsOneWidget);
  });

  testWidgets('tapping a nasabah opens the detail sheet', (tester) async {
    listAs([nasabahRow('1')]);
    api.on('GET', '$_path/1', json: <String, dynamic>{});
    await open(tester);

    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailNasabahBottomSheet), findsOneWidget);
  });

  group('pending submissions', () {
    Future<void> openPending(WidgetTester tester) async {
      listAs([nasabahRow('p1', nama: 'Calon Nasabah', status: 'pending')]);
      await open(tester);
      // The first "Menunggu" is the filter chip; the row's badge comes later.
      await tester.tap(find.text('Menunggu').first);
      await tester.pumpAndSettle();
    }

    testWidgets('are marked and offer approve or reject', (tester) async {
      await openPending(tester);
      expect(find.text('Calon Nasabah'), findsOneWidget);

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();

      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });

    testWidgets('approving sends the decision', (tester) async {
      api.on('POST', '$_path/p1/approve', json: {});
      await openPending(tester);

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Setujui'));
      await pumpToast(tester);

      expect(api.requests.any((r) => r.path == '$_path/p1/approve'), isTrue);
      await settleToasts(tester);
    });

    testWidgets('a failed decision shows the error', (tester) async {
      api.on('POST', '$_path/p1/reject',
          status: 409, json: {'error': 'Sudah diputuskan'});
      await openPending(tester);

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tolak'));
      await pumpToast(tester);

      expect(find.text('Sudah diputuskan'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('dismissing the action sheet changes nothing', (tester) async {
      await openPending(tester);
      final before = api.requests.length;

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(api.requests.length, before);
    });
  });
}
