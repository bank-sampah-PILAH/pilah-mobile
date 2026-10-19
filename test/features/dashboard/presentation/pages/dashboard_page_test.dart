import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_widgets.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_statistics_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_upcoming_schedule_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_web_kpi_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/total_kas_card.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/dashboard_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

class _ActivityCubit extends MockCubit<RecentActivityState>
    implements RecentActivityCubit {}

class _DashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

class _EmptyReportingDataSource implements DashboardReportingDataSource {
  @override
  Future<List<OperationalTrendBucket>> getOperationalTrends({
    required DashboardReportRange range,
    required TrendGranularity granularity,
  }) async =>
      const [];

  @override
  Future<List<WasteCategoryTotal>> getWasteCategories({
    required DashboardReportRange range,
  }) async =>
      const [];
}

class _EmptyJadwalRepository implements JadwalRepository {
  @override
  Future<Either<NetworkException, JadwalPageResult>> getJadwal({
    required int page,
    DateTime? date,
    DateTime? dateTo,
  }) async =>
      Right(JadwalPageResult(
        items: const [],
        totalCount: 0,
        hasMore: false,
      ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StubApi api;
  late DashboardCubit dashboard;
  late _ActivityCubit activity;
  late MockAuthBloc auth;

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));
  setUp(() async {
    await di.reset();
    di.registerSingleton<DashboardReportingDataSource>(
        _EmptyReportingDataSource());
    di.registerSingleton<JadwalRepository>(_EmptyJadwalRepository());
  });
  tearDown(() => di.reset());

  void arrange({
    Map<String, dynamic> stats = const {},
    AuthenticationStates? session,
    DashboardCubit? dashboardCubit,
  }) {
    api = StubApi();
    api.on('GET', '/api/v1/dashboard/stats', json: stats);
    dashboard = dashboardCubit ?? buildDashboardCubit(api);
    if (dashboardCubit == null) addTearDown(dashboard.close);
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

  Future<void> pumpDashboardPage(
    WidgetTester tester, {
    bool? isWeb,
    Size size = const Size(800, 1600),
  }) async {
    final router = await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: activity),
          BlocProvider<AuthenticationBloc>.value(value: auth),
        ],
        child: DashboardPage(isWeb: isWeb),
      ),
      size: size,
    );
    expect(router, isNotNull);
  }

  _DashboardCubit emptyDashboardCubit() {
    final cubit = _DashboardCubit();
    whenListen(
      cubit,
      const Stream<DashboardState>.empty(),
      initialState: const DashboardState(),
    );
    when(() => cubit.loadStats(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
    return cubit;
  }

  testWidgets('header greets the pengelola and links to the profile',
      (tester) async {
    arrange();
    await pump(tester, const DashboardHeader());

    expect(find.text('Bank Sampah Melati'), findsOneWidget);
    expect(find.textContaining('Selamat datang, Siti Aminah'), findsOneWidget);
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
    expect(find.textContaining('Selamat datang, Pengurus'), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('header copes with no session at all', (tester) async {
    arrange(session: Unauthenticated());
    await pump(tester, const DashboardHeader());

    expect(find.textContaining('Selamat datang, Pengurus'), findsOneWidget);
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
    if (kIsWeb) return;
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

  testWidgets('web dashboard shows reports to Pengurus', (tester) async {
    arrange(dashboardCubit: emptyDashboardCubit());
    await pumpDashboardPage(tester, isWeb: true);
    await tester.pumpAndSettle();

    expect(find.byType(DashboardWebKpiSection), findsOneWidget);
    expect(find.byType(DashboardReportsSection), findsOneWidget);
    expect(find.byType(DashboardUpcomingScheduleSection), findsOneWidget);
    expect(find.byType(TotalKasCard), findsNothing);
  });

  testWidgets('a wide web dashboard leaves the profile to the sidebar',
      (tester) async {
    arrange(dashboardCubit: emptyDashboardCubit());
    await pumpDashboardPage(tester, isWeb: true, size: const Size(1440, 1800));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardHeader), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('a wide web dashboard keeps the web gutter and top space',
      (tester) async {
    arrange(dashboardCubit: emptyDashboardCubit());
    await pumpDashboardPage(tester, isWeb: true, size: const Size(1000, 1800));
    await tester.pumpAndSettle();

    final header = tester.getTopLeft(find.byType(DashboardHeader));
    expect(header.dx, 32);
    expect(header.dy, 24);
  });

  testWidgets('a narrow web dashboard keeps the avatar, with no sidebar',
      (tester) async {
    arrange(dashboardCubit: emptyDashboardCubit());
    await pumpDashboardPage(tester, isWeb: true, size: const Size(400, 1800));
    await tester.pumpAndSettle();

    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('web details form a desktop grid and stack on narrow screens',
      (tester) async {
    arrange(dashboardCubit: emptyDashboardCubit());
    await pumpDashboardPage(tester, isWeb: true, size: const Size(1440, 1800));
    await tester.pumpAndSettle();

    final schedule = find.byType(DashboardUpcomingScheduleSection);
    final activitySection = find.byType(RecentActivitySection);
    expect(
        tester.getTopLeft(schedule).dy, tester.getTopLeft(activitySection).dy);
    expect(tester.getTopLeft(schedule).dx,
        lessThan(tester.getTopLeft(activitySection).dx));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(375, 1800);
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(schedule).dx, tester.getTopLeft(activitySection).dx);
    expect(tester.getTopLeft(schedule).dy,
        lessThan(tester.getTopLeft(activitySection).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('web dashboard uses the web default for Pengurus',
      (tester) async {
    if (!kIsWeb) return;
    arrange(dashboardCubit: emptyDashboardCubit());
    await pumpDashboardPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(DashboardReportsSection), findsOneWidget);
    expect(find.byType(DashboardUpcomingScheduleSection), findsOneWidget);
  });

  testWidgets('web dashboard uses native sections for other roles',
      (tester) async {
    arrange(
      session: Authenticated(authEntity: testAuth(role: 'nasabah')),
      dashboardCubit: emptyDashboardCubit(),
    );
    await pumpDashboardPage(tester, isWeb: true);
    await tester.pumpAndSettle();

    expect(find.byType(DashboardWebKpiSection), findsNothing);
    expect(find.byType(DashboardReportsSection), findsNothing);
    expect(find.byType(DashboardUpcomingScheduleSection), findsNothing);
    expect(find.byType(TotalKasCard), findsOneWidget);
    expect(find.byType(DashboardStatisticsSection), findsOneWidget);
  });

  testWidgets('web dashboard uses native sections without a session',
      (tester) async {
    arrange(
      session: Unauthenticated(),
      dashboardCubit: emptyDashboardCubit(),
    );
    await pumpDashboardPage(tester, isWeb: true);
    await tester.pumpAndSettle();

    expect(find.byType(DashboardWebKpiSection), findsNothing);
    expect(find.byType(DashboardReportsSection), findsNothing);
    expect(find.byType(DashboardUpcomingScheduleSection), findsNothing);
    expect(find.byType(TotalKasCard), findsOneWidget);
  });
}
