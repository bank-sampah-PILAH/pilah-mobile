import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_statistics_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/total_kas_card.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/dashboard_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

class _ActivityCubit extends MockCubit<RecentActivityState>
    implements RecentActivityCubit {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  late StubApi api;
  late DashboardCubit dashboard;
  late _ActivityCubit activity;
  late MockAuthBloc auth;

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  void arrange({
    Map<String, dynamic> stats = const {},
    AuthenticationStates? session,
  }) {
    api = StubApi();
    api.on('GET', '/api/v1/dashboard/stats', json: stats);
    dashboard = buildDashboardCubit(api);
    addTearDown(dashboard.close);
    activity = _ActivityCubit();
    whenListen(activity, const Stream<RecentActivityState>.empty(),
        initialState: RecentActivityLoaded(const []));
    when(() => activity.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
    auth = authBlocIn(session ?? Authenticated(authEntity: testAuth()));
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    final router = await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: activity),
          BlocProvider<AuthenticationBloc>.value(value: auth),
        ],
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
      extraRoutes: ['/profile'],
      size: const Size(800, 1600),
    );
    expect(router, isNotNull);
  }

  testWidgets('header greets the pengelola and links to the profile',
      (tester) async {
    arrange();
    await pump(tester, const DashboardHeader());

    expect(find.text('Bank Sampah Melati'), findsOneWidget);
    expect(find.text('Selamat datang, Siti Aminah '), findsOneWidget);
    expect(find.text('SA'), findsOneWidget);

    await tester.tap(find.text('SA'));
    await tester.pumpAndSettle();
    expect(find.text('route:/profile'), findsOneWidget);
  });

  testWidgets('header falls back to generic labels when the profile is blank',
      (tester) async {
    arrange(session: Authenticated(authEntity: testAuth(name: ' ', bank: ' ')));
    await pump(tester, const DashboardHeader());

    expect(find.text('Bank Sampah'), findsOneWidget);
    expect(find.text('Selamat datang, Pengelola '), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('header copes with no session at all', (tester) async {
    arrange(session: Unauthenticated());
    await pump(tester, const DashboardHeader());

    expect(find.text('Selamat datang, Pengelola '), findsOneWidget);
  });

  testWidgets('total kas shows each loading state', (tester) async {
    arrange(stats: {'total_nilai_bulan_ini': '1234567'});
    await pump(tester, const TotalKasCard());
    expect(find.text('Memuat...'), findsOneWidget);

    await tester.runAsync(dashboard.loadStats);
    await tester.pump();
    expect(find.text('Rp 1.234.567'), findsOneWidget);

    api.on('GET', '/api/v1/dashboard/stats', status: 500, json: {});
    await tester.runAsync(dashboard.loadStats);
    await tester.pump();
    expect(find.text('Rp —'), findsOneWidget);
  });

  testWidgets('statistics show dashes until loaded, then the figures',
      (tester) async {
    arrange(stats: {
      'nasabah_aktif': 12,
      'total_sampah_kg_bulan_ini': '3.5',
      'transaksi_bulan_ini': 9,
    });
    await pump(tester, const DashboardStatisticsSection());
    expect(find.text('—'), findsNWidgets(3));

    await tester.runAsync(dashboard.loadStats);
    await tester.pump();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('3,5 kg'), findsOneWidget);
    expect(find.text('9 Trx'), findsOneWidget);
  });

  testWidgets('the page loads both feeds and refreshes them on pull',
      (tester) async {
    arrange(stats: {'total_nilai_bulan_ini': '5000'});
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: activity),
          BlocProvider<AuthenticationBloc>.value(value: auth),
        ],
        child: const DashboardPage(),
      ),
      size: const Size(800, 1600),
    );

    await tester.pumpAndSettle();
    verify(() => activity.load()).called(1);
    expect(find.text('Rp 5.000'), findsOneWidget);

    await tester.fling(
        find.byType(SingleChildScrollView).first, const Offset(0, 500), 1000);
    await tester.pumpAndSettle();

    verify(() => auth.add(any(that: isA<RefreshUserRequested>()))).called(1);
    expect(api.requests.where((r) => r.path.endsWith('/stats')), hasLength(2));
    verify(() => activity.load(silent: true)).called(1);
  });
}
