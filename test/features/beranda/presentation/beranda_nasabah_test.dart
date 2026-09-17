import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/services/di.dart';

class _AuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _DashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

class _ActivityCubit extends MockCubit<RecentActivityState>
    implements RecentActivityCubit {}

// First TDD slice: the landing screen and its entry points. Destination pages
// and their data will be covered in subsequent slices, without inventing URLs.
// The current session contract has no separate membership-status field:
// dashboard + nasabah + active bank is the available onboarded-session fixture.
AuthEntity _nasabah(String bankName) => AuthEntity(
  id: 'nasabah-225',
  name: 'Siti Aminah',
  email: 'siti@example.test',
  photoUrl: '',
  token: 'test-token',
  role: 'nasabah',
  nextStep: 'dashboard',
  bankSampahStatus: 'active',
  bankSampahNama: bankName,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final router = AppRouterConfig.getRouter();
  tearDownAll(router.dispose);

  Future<void> loginAsNasabah(
    WidgetTester tester, {
    String bankName = 'Bank Sampah Melati',
  }) async {
    final auth = _AuthBloc();
    final sessions = StreamController<AuthenticationStates>();
    final dashboard = _DashboardCubit();
    final activity = _ActivityCubit();
    final invites = InviteTokenStore();

    di.registerSingleton<InviteTokenStore>(invites);
    whenListen(auth, sessions.stream, initialState: Unauthenticated());
    whenListen(
      dashboard,
      const Stream<DashboardState>.empty(),
      initialState: const DashboardState(status: DashboardStatus.loaded),
    );
    whenListen(
      activity,
      const Stream<RecentActivityState>.empty(),
      initialState: const RecentActivityLoaded([]),
    );
    when(() => dashboard.loadStats()).thenAnswer((_) async {});
    when(() => activity.load()).thenAnswer((_) async {});

    addTearDown(() async {
      await sessions.close();
      await auth.close();
      await dashboard.close();
      await activity.close();
      await di.unregister<InviteTokenStore>();
      invites.dispose();
    });

    router.go(LoginPage.route);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: auth),
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: activity),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    // Exercise the production login listener and router, not a test-only route.
    sessions.add(Authenticated(authEntity: _nasabah(bankName)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LoginPage), findsNothing);
  }

  group('PIL-225 beranda nasabah — first red slice', () {
    testWidgets('nasabah aktif mendarat di Beranda setelah login', (
      tester,
    ) async {
      await loginAsNasabah(tester);
      expect(find.text('Beranda'), findsWidgets);
    });

    for (final label in ['Saldo', 'Riwayat Aktivitas', 'Detail Bank Sampah']) {
      testWidgets('beranda menyediakan akses aktif ke $label', (tester) async {
        final semantics = tester.ensureSemantics();
        addTearDown(semantics.dispose);
        await loginAsNasabah(tester);
        final entry = find.text(label);
        expect(entry, findsOneWidget);
        await tester.ensureVisible(entry);
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(entry)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label harus bisa diakses, bukan sekadar teks statis',
        );
      });
    }

    for (final bankName in ['Bank Sampah Melati', 'Bank Sampah Kenanga']) {
      testWidgets('menampilkan unit milik akun: $bankName', (tester) async {
        await loginAsNasabah(tester, bankName: bankName);
        expect(find.text(bankName), findsOneWidget);
        final otherBank = bankName == 'Bank Sampah Melati'
            ? 'Bank Sampah Kenanga'
            : 'Bank Sampah Melati';
        expect(find.text(otherBank), findsNothing);
      });
    }
  });
}
