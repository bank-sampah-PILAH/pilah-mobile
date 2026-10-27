import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../support/stub_api.dart';
import '../../../support/auth_support.dart';

class _JadwalRepository extends Mock implements JadwalRepository {}

/// A preview repository whose home carries the given balance and activities.
class _HomeRepository extends PreviewNasabahRepository {
  _HomeRepository(this.balanceUpdatedAt, this.activities);

  final DateTime? balanceUpdatedAt;
  final List<NasabahActivity> activities;
  final asked = <String?>[];

  @override
  Future<NasabahHome> home({String? membershipId}) async {
    asked.add(membershipId);
    return NasabahHome(
      await profile(),
      membershipId ?? 'membership-1',
      await bank(''),
      NasabahBalance('12500.50', balanceUpdatedAt),
      activities,
    );
  }
}

void main() {
  late TestAuthenticationNotifier auth;
  late _JadwalRepository jadwal;
  late StubApi api;

  setUp(() {
    auth = authNotifierIn(Authenticated(
      authEntity: AuthEntity(
        id: 'nasabah-1',
        name: 'Siti',
        email: 'siti@example.test',
        photoUrl: '',
        token: 'token',
        role: 'nasabah',
        nextStep: 'nasabah_dashboard',
      ),
    ));
    jadwal = _JadwalRepository();
    api = StubApi();
    api.on('GET', '/api/v1/nasabah/me/pengumuman/beranda', json: {
      'items': [
        {
          'id': 'p2',
          'judul': 'Pengumuman baru',
          'isi': 'Isi pengumuman.',
          'terbit_pada': '2026-10-16T03:00:00Z',
          'dibaca': false,
        },
        {
          'id': 'p1',
          'judul': 'Pengumuman lama',
          'isi': 'Isi oke.',
          'terbit_pada': '2026-10-01T03:00:00Z',
          'dibaca': true,
        },
      ],
      'unread_count': 1,
    });
    when(() => jadwal.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => const Right(
          JadwalPageResult(items: [], totalCount: 0, hasMore: false)),
    );
    di.registerSingleton<JadwalRepository>(jadwal);
    di.registerSingleton<NasabahPengumumanRepository>(
        NasabahPengumumanRepository(api.network));
  });

  tearDown(() async {
    if (di.isRegistered<NasabahRepository>()) {
      await di.unregister<NasabahRepository>();
    }
    await di.unregister<JadwalRepository>();
    await di.unregister<NasabahPengumumanRepository>();
  });

  Future<void> pumpHome(
    WidgetTester tester,
    NasabahRepository repository, {
    Map<String, Widget Function(BuildContext, GoRouterState)> extraRoutes =
        const {},
  }) async {
    di.registerSingleton<NasabahRepository>(repository);
    final router = GoRouter(initialLocation: '/beranda', routes: [
      GoRoute(path: '/beranda', builder: (_, __) => const BerandaNasabahPage()),
      GoRoute(
        path: '/jadwal',
        builder: (_, state) => const Scaffold(body: Text('halaman jadwal')),
      ),
      GoRoute(
        path: AppLocations.history,
        builder: (_, state) => Scaffold(
            body:
                Text('riwayat ${state.uri.queryParameters['keanggotaan_id']}')),
      ),
      for (final entry in extraRoutes.entries)
        GoRoute(path: entry.key, builder: entry.value),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  // The greeting follows the clock, so each time of day is checked against a
  // fixed one and the result does not depend on when the suite runs.
  const greetings = {
    5: 'Selamat pagi',
    12: 'Selamat siang',
    16: 'Selamat sore',
    20: 'Selamat malam',
  };
  for (final entry in greetings.entries) {
    testWidgets('greets ${entry.value.toLowerCase()} at ${entry.key}:00',
        (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 10, 6, entry.key)), () async {
        await pumpHome(tester, _HomeRepository(null, const []));

        expect(find.text(entry.value), findsOneWidget);
      });
    });
  }

  testWidgets('the balance card names the latest activity and its date',
      (tester) async {
    await pumpHome(
        tester,
        _HomeRepository(null, [
          NasabahActivity(
              'a1', DateTime(2026, 9, 23, 9), 'pencairan', '5000.00'),
        ]));

    expect(find.text('Pencairan · 23/09/2026'), findsOneWidget);
  });

  testWidgets('an unrecognised activity type is shown as sent', (tester) async {
    await pumpHome(
        tester,
        _HomeRepository(null, [
          NasabahActivity('a1', DateTime(2026, 9, 23, 9), 'koreksi', '1000.00'),
        ]));

    expect(find.text('koreksi · 23/09/2026'), findsOneWidget);
  });

  testWidgets('without activity it says when the balance was updated',
      (tester) async {
    await pumpHome(tester, _HomeRepository(DateTime(2026, 9, 20, 9), const []));

    expect(find.text('Diperbarui 20/09/2026'), findsOneWidget);
  });

  testWidgets('Semua links go to the schedule and to the history',
      (tester) async {
    await pumpHome(tester, _HomeRepository(null, const []));

    await tester.tap(find.widgetWithText(TextButton, 'Semua').first);
    await tester.pumpAndSettle();
    expect(find.text('halaman jadwal'), findsOneWidget);

    // Back to the home page for the second link.
    final router = GoRouter.of(tester.element(find.text('halaman jadwal')));
    router.go('/beranda');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Semua').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Semua').last);
    await tester.pumpAndSettle();
    expect(find.text('riwayat membership-1'), findsOneWidget);
  });

  testWidgets('choosing the bank again reloads the home without a membership',
      (tester) async {
    final repository = _HomeRepository(null, const []);
    await pumpHome(tester, repository);
    expect(repository.asked, [null]);

    await tester.tap(find.byTooltip('Pilih ulang bank sampah'));
    await tester.pumpAndSettle();

    expect(repository.asked, [null, null]);
  });

  testWidgets('a failing schedule request is reported in its own card',
      (tester) async {
    when(() => jadwal.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => Left(GeneralException(message: 'offline')),
    );
    await pumpHome(tester, _HomeRepository(null, const []));

    expect(find.text('offline'), findsOneWidget);
  });

  group('pengumuman section', () {
    testWidgets(
        'lists the beranda rows with a dot only on the unread one, scoped to '
        'the membership', (tester) async {
      await pumpHome(tester, _HomeRepository(null, const []));

      expect(find.text('Pengumuman baru'), findsOneWidget);
      expect(find.byKey(const ValueKey('beranda-pengumuman-baru')),
          findsOneWidget);
      expect(
        api.last.query['keanggotaan_id'],
        'membership-1',
      );
    });

    testWidgets('Semua opens the pengumuman list', (tester) async {
      await pumpHome(tester, _HomeRepository(null, const []), extraRoutes: {
        '/pengumuman': (_, __) => const Scaffold(body: Text('daftar')),
      });

      // Headings carry their own Semua (Jadwal, Pengumuman, Terbaru); the
      // middle one is Pengumuman's.
      final semuaButtons = find.widgetWithText(TextButton, 'Semua');
      await tester.ensureVisible(semuaButtons.at(1));
      await tester.pumpAndSettle();
      await tester.tap(semuaButtons.at(1));
      await tester.pumpAndSettle();

      expect(find.text('daftar'), findsOneWidget);
    });

    testWidgets('tapping a row opens the detail and refreshes on return',
        (tester) async {
      final repository = _HomeRepository(null, const []);
      await pumpHome(tester, repository, extraRoutes: {
        '/pengumuman/detail': (_, __) =>
            const Scaffold(body: Text('detail pengumuman')),
      });

      await tester.ensureVisible(find.text('Pengumuman lama'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengumuman lama'));
      await tester.pumpAndSettle();
      expect(find.text('detail pengumuman'), findsOneWidget);

      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.pop();
      await tester.pumpAndSettle();

      // Coming back re-fetches the section so a read dots gone.
      expect(
        api.requests
            .where((call) => call.path.endsWith('/pengumuman/beranda'))
            .length,
        greaterThanOrEqualTo(2),
      );
    });

    testWidgets('tapping an unread row fires the baca POST', (tester) async {
      api.on('POST', '/api/v1/nasabah/me/pengumuman/p2/baca',
          json: {'id': 'p2', 'dibaca': true});
      await pumpHome(tester, _HomeRepository(null, const []), extraRoutes: {
        '/pengumuman/detail': (_, __) =>
            const Scaffold(body: Text('detail pengumuman')),
      });

      await tester.ensureVisible(find.text('Pengumuman baru'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengumuman baru'));
      await tester.pumpAndSettle();
      expect(find.text('detail pengumuman'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));

      final baca = api.requests.lastWhere(
        (call) => call.path == '/api/v1/nasabah/me/pengumuman/p2/baca',
      );
      expect(baca.query['keanggotaan_id'], 'membership-1');
      // An already-read row does not post again.
      expect(
        api.requests
            .where(
                (call) => call.path == '/api/v1/nasabah/me/pengumuman/p1/baca')
            .isEmpty,
        isTrue,
      );
    });

    testWidgets('Semua opens the list scoped to the membership',
        (tester) async {
      await pumpHome(tester, _HomeRepository(null, const []), extraRoutes: {
        '/pengumuman': (_, state) => Scaffold(
            body:
                Text('daftar ${state.uri.queryParameters['keanggotaan_id']}')),
      });

      // Headings carry their own Semua (Jadwal, Pengumuman, Terbaru); the
      // middle one is Pengumuman's.
      final semuaButtons = find.widgetWithText(TextButton, 'Semua');
      await tester.ensureVisible(semuaButtons.at(1));
      await tester.pumpAndSettle();
      await tester.tap(semuaButtons.at(1));
      await tester.pumpAndSettle();
      expect(find.text('daftar membership-1'), findsOneWidget);
    });

    testWidgets('an empty section shows the standalone card', (tester) async {
      api.on('GET', '/api/v1/nasabah/me/pengumuman/beranda',
          json: {'items': [], 'unread_count': 0});
      await pumpHome(tester, _HomeRepository(null, const []));

      expect(find.text('Belum ada pengumuman.'), findsOneWidget);
    });
  });

  testWidgets('every activity type keeps its title in the shared list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NasabahActivityList(activities: [
          NasabahActivity('a', DateTime(2026, 9, 1), 'setoran', '1000.00'),
          NasabahActivity('b', DateTime(2026, 9, 2), 'pencairan', '500.00'),
          NasabahActivity('c', DateTime(2026, 9, 3), 'koreksi', '100.00'),
        ]),
      ),
    ));

    expect(find.text('Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.text('koreksi'), findsOneWidget);
  });
}
