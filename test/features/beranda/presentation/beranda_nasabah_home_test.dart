import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

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
  late _Auth auth;
  late _JadwalRepository jadwal;

  setUp(() {
    auth = _Auth();
    jadwal = _JadwalRepository();
    when(() => jadwal.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => const Right(
          JadwalPageResult(items: [], totalCount: 0, hasMore: false)),
    );
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: Authenticated(
        authEntity: AuthEntity(
          id: 'nasabah-1',
          name: 'Siti',
          email: 'siti@example.test',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
          nextStep: 'nasabah_dashboard',
        ),
      ),
    );
    di.registerSingleton<JadwalRepository>(jadwal);
  });

  tearDown(() async {
    if (di.isRegistered<NasabahRepository>()) {
      await di.unregister<NasabahRepository>();
    }
    await di.unregister<JadwalRepository>();
    await auth.close();
  });

  Future<void> pumpHome(
      WidgetTester tester, NasabahRepository repository) async {
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
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
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
