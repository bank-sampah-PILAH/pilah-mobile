import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockNasabahCubit extends MockCubit<NasabahState>
    implements NasabahCubit {}

class _MockHargaCubit extends MockCubit<HargaState> implements HargaCubit {}

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {}

class _MockTransaksiCubit extends MockCubit<TransaksiState>
    implements TransaksiCubit {}

class _MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

class _MockRecentActivityCubit extends MockCubit<RecentActivityState>
    implements RecentActivityCubit {}

class _MockRiwayatAktivitasCubit extends MockCubit<RiwayatAktivitasState>
    implements RiwayatAktivitasCubit {}

class _MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class _MockOnboardingDataSource extends Mock
    implements OnboardingRemoteDataSource {}

class _MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _FakeAuthenticationEvent extends Fake implements AuthenticationEvent {}

void main() {
  late _MockAuthenticationBloc authenticationBloc;
  late StreamController<AuthenticationStates> authenticationStates;
  late _MockNasabahCubit nasabah;
  late _MockHargaCubit harga;
  late _MockJadwalCubit jadwal;
  late _MockTransaksiCubit transaksi;
  late _MockDashboardCubit dashboard;
  late _MockRecentActivityCubit recentActivity;
  late _MockRiwayatAktivitasCubit riwayatAktivitas;
  late _MockProfileCubit profile;
  // Real, not mocked: the draft it holds is the thing under test, and a mock
  // would only confirm that a method was called rather than that the data is
  // actually gone.
  late OnboardingCubit onboarding;

  setUpAll(() => registerFallbackValue(_FakeAuthenticationEvent()));

  setUp(() {
    nasabah = _MockNasabahCubit();
    harga = _MockHargaCubit();
    jadwal = _MockJadwalCubit();
    transaksi = _MockTransaksiCubit();
    dashboard = _MockDashboardCubit();
    recentActivity = _MockRecentActivityCubit();
    riwayatAktivitas = _MockRiwayatAktivitasCubit();
    profile = _MockProfileCubit();
    onboarding = OnboardingCubit(_MockOnboardingDataSource());
    authenticationBloc = _MockAuthenticationBloc();
    authenticationStates = StreamController<AuthenticationStates>.broadcast();
    whenListen(
      authenticationBloc,
      authenticationStates.stream,
      initialState: AuthenticationInitial(),
    );
    when(() => nasabah.state).thenReturn(NasabahInitial());
    when(() => harga.state).thenReturn(HargaInitial());
    when(() => jadwal.state).thenReturn(const JadwalInitial());
    when(() => transaksi.state).thenReturn(TransaksiInitial());
    when(() => dashboard.state).thenReturn(const DashboardState());
    when(() => recentActivity.state).thenReturn(RecentActivityInitial());
    when(() => riwayatAktivitas.state)
        .thenReturn(const RiwayatAktivitasState());
    when(() => profile.state).thenReturn(const ProfileState());

    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<AuthenticationBloc>(authenticationBloc);
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    di.registerSingleton<NasabahCubit>(nasabah);
    di.registerSingleton<HargaCubit>(harga);
    di.registerSingleton<JadwalCubit>(jadwal);
    di.registerSingleton<TransaksiCubit>(transaksi);
    di.registerSingleton<DashboardCubit>(dashboard);
    di.registerSingleton<RecentActivityCubit>(recentActivity);
    di.registerSingleton<RiwayatAktivitasCubit>(riwayatAktivitas);
    di.registerSingleton<ProfileCubit>(profile);
    di.registerSingleton<OnboardingCubit>(onboarding);
  });

  tearDown(() async {
    await authenticationStates.close();
    if (!onboarding.isClosed) await onboarding.close();
    await di.reset();
  });

  testWidgets(
      'resetSessionScopedState keeps a pending invite token across logout',
      (tester) async {
    // A user tapped an invite link while signed in as the wrong account and is
    // logging out to sign in as the invited one.
    di<InviteTokenStore>().save('invite-token-abc');
    expect(di<InviteTokenStore>().hasToken, isTrue);

    // Half-way through the registration wizard when they logged out.
    onboarding.saveProfileDraft(const CompleteProfileRequest(
      nama: 'Sari Dewi',
      jenisKelamin: 'perempuan',
      tanggalLahir: '1990-04-17',
      noHp: '81234567890',
    ));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<NasabahCubit>.value(value: nasabah),
          BlocProvider<HargaCubit>.value(value: harga),
          BlocProvider<JadwalCubit>.value(value: jadwal),
          BlocProvider<TransaksiCubit>.value(value: transaksi),
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: recentActivity),
          BlocProvider<RiwayatAktivitasCubit>.value(value: riwayatAktivitas),
          BlocProvider<ProfileCubit>.value(value: profile),
          BlocProvider<OnboardingCubit>.value(value: onboarding),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => resetSessionScopedState(context),
              child: const Text('logout'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('logout'));
    await tester.pump();

    expect(
      di<InviteTokenStore>().hasToken,
      isTrue,
      reason:
          'switching accounts is a step inside the invite flow, not an exit '
          'from it — the token has to survive until it is redeemed or refused',
    );
    // Only the invite token is exempt; the session cubits still reset.
    verify(() => nasabah.reset()).called(1);
    verify(() => harga.reset()).called(1);
    verify(() => jadwal.reset()).called(1);
    verify(() => transaksi.reset()).called(1);
    verify(() => dashboard.reset()).called(1);
    verify(() => recentActivity.reset()).called(1);
    verify(() => riwayatAktivitas.reset()).called(1);
    verify(
      () => profile.reset(),
      // Holds the bank sampah's WhatsApp template and, more sensitively, any
      // logo picked but not yet uploaded — a path into the previous user's
      // gallery that would otherwise be sent as the next bank's logo.
    ).called(1);
    expect(
      onboarding.hasProfileDraft,
      isFalse,
      reason: 'the draft is one person’s name, phone and date of birth — left '
          'behind it would prefill the next account’s form with it, and be '
          'submitted under their credentials',
    );
  });

  testWidgets('logs out and warns when a web session has an unsupported role',
      (tester) async {
    await tester.pumpWidget(App(isWebOverride: true));
    final router = AppRouterConfig.getRouter();
    addTearDown(router.dispose);

    router.go(ForgotPasswordPage.route);
    await tester.pumpAndSettle();
    expect(rootNavigatorKey.currentContext, isNotNull);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);

    authenticationStates.add(Unauthenticated());
    await tester.pump();
    authenticationStates.add(
      Authenticated(
        authEntity: const AuthEntity(
          name: 'Nasabah',
          email: 'nasabah@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );
    for (var i = 0;
        i < 10 && find.text('Akses web tidak tersedia').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final events = verify(() => authenticationBloc.add(captureAny())).captured;
    expect(events.whereType<LogoutRequested>(), hasLength(1));
    expect(find.text('Akses web tidak tersedia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
