import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_kelola_page.dart';

import '../../../../support/pengumuman_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id,
        {required String judul, required String status}) =>
    {
      'id': id,
      'judul': judul,
      'isi': 'Isi $id.',
      'status': status,
      'terbit_pada': '2026-10-15T03:00:00Z',
      'dibuat_oleh_id': 'u1',
    };

void main() {
  // Drains a just-shown (two post-frame callbacks away) toast in one stretch:
  // the stepwise settleToasts drive hits a flushbar pop race on this route.
  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  late StubApi api;

  setUp(() {
    api = StubApi();
  });

  Widget withProvider(Widget child) => ProviderScope(
        overrides: [
          pengumumanProvider.overrideWith(() => PengumumanNotifier(
                buildPengumumanRepository(api),
              )),
        ],
        child: child,
      );

  Future<void> openPage(WidgetTester tester,
      {List<String> extraRoutes = const [],
      bool isWeb = false,
      Size size = const Size(800, 2000)}) async {
    await pumpRouted(
      tester,
      withProvider(PengumumanKelolaPage(isWeb: isWeb)),
      extraRoutes: extraRoutes,
      size: size,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('on the web the create button is in the page header, no FAB',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 0,
      'next': null,
      'results': [],
    });

    await openPage(tester, isWeb: true, size: const Size(1440, 900));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.widgetWithText(AppButton, 'Buat'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Kelola Pengumuman')).dx, 120 + 32,
        reason: 'the title starts at the content column plus the gutter');
    expect(find.byIcon(Icons.arrow_back), findsNothing,
        reason: 'a sidebar destination has nowhere to go back to');
  });

  testWidgets('a phone keeps the FAB and the back header', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 0,
      'next': null,
      'results': [],
    });

    await openPage(tester, size: const Size(390, 844));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('renders rows with their status and the filter chips',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [
        _row('1', judul: 'Masih konsep', status: 'draft'),
        _row('2', judul: 'Sedang berjalan', status: 'terbit'),
      ],
    });

    await openPage(tester);

    expect(find.byKey(const ValueKey('pengumuman-kelola-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pengumuman-kelola-2')), findsOneWidget);
    // The row badge and the filter chip both say "Draft".
    expect(find.text('Draft'), findsNWidgets(2));
    expect(find.widgetWithText(AppChip, 'Semua'), findsOneWidget);
    // Draft rows can be edited; terbit rows can be withdrawn.
    expect(find.text('Ubah'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);
    expect(find.text('Tarik'), findsOneWidget);
  });

  testWidgets('filtering sends the status and swaps the rows', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Masih konsep', status: 'draft')],
    });
    await openPage(tester);

    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 0,
      'next': null,
      'results': <Map<String, dynamic>>[],
    });
    await tester.tap(find.widgetWithText(AppChip, 'Kedaluwarsa'));
    await tester.pumpAndSettle();

    expect(api.last.query['status'], 'kedaluwarsa');
    expect(find.text('Tidak ada pengumuman dengan status ini'), findsOneWidget);
  });

  testWidgets('a declined withdrawal confirmation stays inert', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Sedang berjalan', status: 'terbit')],
    });
    await openPage(tester);

    await tester.tap(find.text('Tarik'));
    await tester.pumpAndSettle();
    expect(find.text('Tarik pengumuman?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Batal').last);
    await tester.pumpAndSettle();
    expect(find.text('Tarik pengumuman?'), findsNothing);
    expect(
      api.requests.where((call) => call.path.contains('tarik')),
      isEmpty,
    );
  });

  testWidgets('confirming the withdrawal posts to tarik', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Sedang berjalan', status: 'terbit')],
    });
    api.on('POST', '/api/v1/pengumuman/1/tarik', json: {'id': '1'});
    await openPage(tester);

    await tester.tap(find.text('Tarik'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Tarik').last);
    await drainToast(tester);

    expect(
      api.requests.any((call) => call.path == '/api/v1/pengumuman/1/tarik'),
      isTrue,
    );
    // The list reloads after the transition.
    expect(
      api.requests.where(
          (call) => call.method == 'GET' && call.path == '/api/v1/pengumuman'),
      hasLength(2),
    );
  });

  testWidgets('canceling a schedule patches the row with a null terbit_pada',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [
        _row('1', judul: 'Menunggu jadwal', status: 'terjadwal'),
      ],
    });
    api.on('PATCH', '/api/v1/pengumuman/1', json: <String, dynamic>{});
    await openPage(tester);

    await tester.tap(find.text('Batalkan Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Batalkan').last);
    await drainToast(tester);

    final call = api.requests.lastWhere((call) => call.method == 'PATCH');
    expect(call.json['terbit_pada'], isNull);
  });

  testWidgets('a failed schedule cancellation reports the failure',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [
        _row('1', judul: 'Menunggu jadwal', status: 'terjadwal'),
      ],
    });
    api.on('PATCH', '/api/v1/pengumuman/1',
        status: 400, json: {'error': 'tidak diizinkan'});
    await openPage(tester);

    await tester.tap(find.text('Batalkan Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Batalkan').last);
    await drainToast(tester);

    // The failed PATCH leaves the row on the list.
    expect(find.byKey(const ValueKey('pengumuman-kelola-1')), findsOneWidget);
  });

  testWidgets('a declined schedule cancellation stays inert', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [
        _row('1', judul: 'Menunggu jadwal', status: 'terjadwal'),
      ],
    });
    await openPage(tester);

    await tester.tap(find.text('Batalkan Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Batal').last);
    await tester.pumpAndSettle();

    expect(
      api.requests.where((call) => call.method == 'PATCH'),
      isEmpty,
    );
  });

  testWidgets('a failed withdrawal keeps the row', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Sedang berjalan', status: 'terbit')],
    });
    api.on('POST', '/api/v1/pengumuman/1/tarik',
        status: 400, json: {'error': 'tidak diizinkan'});
    await openPage(tester);

    await tester.tap(find.text('Tarik'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Tarik').last);
    await drainToast(tester);

    // The failed transition leaves the row on the list, unchanged.
    expect(find.byKey(const ValueKey('pengumuman-kelola-1')), findsOneWidget);
  });

  testWidgets('Hapus on a draft posts delete and reports success',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Masih konsep', status: 'draft')],
    });
    api.on('DELETE', '/api/v1/pengumuman/1', json: null);
    await openPage(tester);
    // The silent reload after the delete sees an empty bank.
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Hapus').last);
    await drainToast(tester);

    expect(
      api.requests.any((call) => call.method == 'DELETE'),
      isTrue,
    );
    expect(find.text('Belum ada pengumuman'), findsOneWidget,
        reason: 'the silent reload has emptied the list');
  });

  testWidgets('Ubah on a draft opens the form route carrying the row',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Masih konsep', status: 'draft')],
    });
    await openPage(tester, extraRoutes: const ['/pengumuman/kelola/ubah']);

    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();

    expect(find.text('route:/pengumuman/kelola/ubah'), findsOneWidget);
  });

  testWidgets('Ubah on a scheduled row opens the form as well', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [
        _row('1', judul: 'Menunggu jadwal', status: 'terjadwal'),
      ],
    });
    await openPage(tester, extraRoutes: const ['/pengumuman/kelola/ubah']);

    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();

    expect(find.text('route:/pengumuman/kelola/ubah'), findsOneWidget);
  });

  testWidgets('a failed next page shows the loading-more caption',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 31,
      'next': 'http://api.test/api/v1/pengumuman?page=2',
      'results': [
        for (var i = 1; i <= 30; i++)
          _row('$i', judul: 'Baris $i', status: 'draft'),
      ],
    });
    await openPage(tester);

    api.fail('GET', '/api/v1/pengumuman');
    for (var i = 0;
        i < 80 && api.requests.every((call) => call.query['page'] != '2');
        i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    expect(api.last.query['page'], '2');
    expect(find.text('Connection Timeout'), findsOneWidget);
  });

  testWidgets('a failed load offers Coba Lagi and reloads', (tester) async {
    api.fail('GET', '/api/v1/pengumuman');
    await openPage(tester);

    expect(find.text('Coba Lagi'), findsOneWidget);

    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Baris 1', status: 'draft')],
    });
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Baris 1'), findsOneWidget);
  });

  testWidgets('the FAB opens a blank form', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 0,
      'next': null,
      'results': <Map<String, dynamic>>[],
    });
    await openPage(tester, extraRoutes: const ['/pengumuman/kelola/ubah']);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('route:/pengumuman/kelola/ubah'), findsOneWidget);
  });

  testWidgets('an unfiltered empty list shows the creation zero state',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
    await openPage(tester);

    expect(find.text('Belum ada pengumuman'), findsOneWidget);
    expect(find.text('Buat pengumuman untuk nasabah bank sampah Anda.'),
        findsOneWidget);
  });

  testWidgets('a list that fills past the viewport pages at its end',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 31,
      'next': 'http://api.test/api/v1/pengumuman?page=2',
      'results': [
        for (var i = 1; i <= 30; i++)
          _row('$i', judul: 'Baris $i', status: 'draft'),
      ],
    });
    await openPage(tester);
    expect(
      api.requests.where((call) => call.query['page'] == '2'),
      isEmpty,
      reason: 'the rows still leave scroll behind: no next-page fetch yet',
    );

    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 31,
      'next': null,
      'results': [_row('31', judul: 'Baris 31', status: 'draft')],
    });
    // Drag toward the bottom in small steps until the near-end listener
    // fetches page 2, then let the appended row land.
    for (var i = 0;
        i < 80 && api.requests.every((call) => call.query['page'] != '2');
        i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    expect(
      api.requests.any((call) => call.query['page'] == '2'),
      isTrue,
    );
    // One more drag reveals the row appended just below the fold.
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pengumuman-kelola-31')), findsOneWidget);
  });

  group('the page header', () {
    Future<void> stubEmpty() async =>
        api.on('GET', '/api/v1/pengumuman', json: {
          'count': 0,
          'next': null,
          'results': [],
        });

    testWidgets('on the web the title stands alone: no back arrow',
        (tester) async {
      await stubEmpty();
      await openPage(tester, isWeb: true, size: const Size(1280, 900));

      expect(find.text('Kelola Pengumuman'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing,
          reason: 'a sidebar destination has nowhere to go back to');
    });

    testWidgets('a narrow browser keeps the plain title and the FAB',
        (tester) async {
      await stubEmpty();
      await openPage(tester, isWeb: true, size: const Size(390, 844));

      expect(find.text('Kelola Pengumuman'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'the header button is for wide windows only');
    });

    testWidgets('in the app, back returns to Profil when nothing was pushed',
        (tester) async {
      await stubEmpty();
      await openPage(tester,
          extraRoutes: ['/profile'], size: const Size(390, 844));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('route:/profile'), findsOneWidget,
          reason: 'the page is a shell branch, so there is nothing to pop');
    });

    testWidgets('in the app, back pops when the page was pushed',
        (tester) async {
      await stubEmpty();
      await pumpRouted(
        tester,
        withProvider(const PengumumanKelolaPage(isWeb: false)),
        size: const Size(390, 844),
        pushed: true,
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('route:/'), findsOneWidget);
    });
  });

  testWidgets('returning to the retained branch reloads the list',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 0,
      'next': null,
      'results': [],
    });
    var active = true;
    late StateSetter flip;
    await pumpRouted(
      tester,
      withProvider(StatefulBuilder(builder: (context, setState) {
        flip = setState;
        return TickerMode(
          enabled: active,
          child: const PengumumanKelolaPage(isWeb: false),
        );
      })),
      size: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    final before = api.requests.length;

    flip(() => active = false); // another tab takes over
    await tester.pumpAndSettle();
    expect(api.requests.length, before, reason: 'leaving does not reload');

    flip(() => active = true); // the branch is selected again
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100)); // let the request run
    expect(api.requests.length, before + 1,
        reason: 'a retained page must refresh when it comes back');
  });
}
