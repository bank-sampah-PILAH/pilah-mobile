import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

import '../../../../support/pump_app.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockOnboardingDataSource extends Mock
    implements OnboardingRemoteDataSource {}

class _FakeRegisterNasabahRequest extends Fake
    implements RegisterNasabahRequest {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

class _FakeCompleteProfileRequest extends Fake
    implements CompleteProfileRequest {}

const _bank = BankSampahDirectoryEntity(
  id: 'bank-1',
  nama: 'Bank Sampah BTH',
  alamat: 'Kel. Kukusan',
  kota: 'Depok',
  fotoLogo: '',
);

const _joinedMembership = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-joined',
  bankSampahNama: 'Bank Sampah Lama',
  bankSampahKota: 'Bogor',
  status: 'approved',
  isActive: true,
);

const _draft = CompleteProfileRequest(
  nama: 'Nasabah PILAH',
  jenisKelamin: 'perempuan',
  tanggalLahir: '1998-05-20',
  noHp: '81234567890',
  alamat: 'Jl. Melati No. 5',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRegisterNasabahRequest());
    registerFallbackValue(_FakeAuthEvent());
    registerFallbackValue(_FakeCompleteProfileRequest());
  });

  late _MockAuthBloc auth;
  late _MockOnboardingDataSource dataSource;
  late OnboardingCubit onboarding;

  setUp(() {
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: AuthenticationInitial(),
    );
    dataSource = _MockOnboardingDataSource();
    onboarding = OnboardingCubit(dataSource);
    when(() => dataSource.listBankSampahDirectory())
        .thenAnswer((_) async => [_bank]);
    when(() => dataSource.listMyMemberships()).thenAnswer((_) async => []);
  });

  tearDown(() => onboarding.close());

  Future<GoRouter> pump(WidgetTester tester,
      {bool pushed = false, List<String> extraRoutes = const []}) async {
    final router = GoRouter(
      initialLocation:
          pushed ? '/complete-profile' : RegisterNasabahScreen.route,
      routes: [
        GoRoute(
          path: '/complete-profile',
          builder: (_, __) => const Scaffold(body: Text('COMPLETE PROFILE')),
          routes: [
            GoRoute(
              path: 'register-nasabah',
              builder: (_, __) => const RegisterNasabahScreen(),
            ),
          ],
        ),
        GoRoute(
          path: RegisterNasabahScreen.route,
          builder: (_, __) => const RegisterNasabahScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('NASABAH DASHBOARD')),
        ),
        for (final path in extraRoutes)
          GoRoute(
            path: path,
            builder: (_, __) => Scaffold(body: Text('route:$path')),
          ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: auth),
          BlocProvider<OnboardingCubit>.value(value: onboarding),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    if (pushed) {
      router.push('/complete-profile/register-nasabah');
      await tester.pumpAndSettle();
    }

    return router;
  }

  testWidgets('submits the picked bank, then routes onward', (tester) async {
    when(() => dataSource.registerNasabah(
        const RegisterNasabahRequest(bankSampahId: 'bank-1'))).thenAnswer(
      (_) async => const OnboardingResult(nextStep: 'nasabah_dashboard'),
    );

    await pump(tester);

    // Nothing picked yet.
    expect(find.text('Tap untuk pilih bank sampah'), findsOneWidget);

    await tester.tap(find.text('Tap untuk pilih bank sampah'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Sampah BTH'), findsOneWidget);
    await tester.tap(find.text('Bank Sampah BTH'));
    await tester.pumpAndSettle();

    // Bottom sheet closed, selection now shown on the form.
    expect(find.text('Bank Sampah BTH'), findsOneWidget);

    await tester.tap(find.text('Ajukan Pendaftaran'));
    await tester.pumpAndSettle();

    verify(() => dataSource.registerNasabah(
        const RegisterNasabahRequest(bankSampahId: 'bank-1'))).called(1);
    verify(() => auth.add(
          any<AuthenticationEvent>(that: isA<RefreshUserRequested>()),
        )).called(1);
    expect(find.text('NASABAH DASHBOARD'), findsOneWidget);
  });

  testWidgets('blocks submit and shows an inline error with no bank picked',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Ajukan Pendaftaran'));
    await tester.pumpAndSettle();

    expect(find.text('Bank sampah wajib dipilih'), findsOneWidget);
    verifyNever(() => dataSource.registerNasabah(any()));
  });

  testWidgets('hides the Kembali button when reached directly', (tester) async {
    await pump(tester);

    expect(find.text('Kembali'), findsNothing);
  });

  testWidgets('shows the onboarding stepper with step 2 highlighted',
      (tester) async {
    await pump(tester);

    expect(find.text('Profil Diri'), findsOneWidget);
    expect(find.text('Pilih Bank Sampah'), findsOneWidget);
  });

  testWidgets(
      'shows Kembali mid-wizard and pops back to the profile screen underneath',
      (tester) async {
    onboarding.saveProfileDraft(_draft);

    await pump(tester, pushed: true);

    expect(find.text('Kembali'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('COMPLETE PROFILE'), findsOneWidget);
  });

  testWidgets('sends the banked profile draft before the membership request',
      (tester) async {
    onboarding.saveProfileDraft(_draft);
    when(() => dataSource.completeProfile(_draft)).thenAnswer(
      (_) async => const OnboardingResult(nextStep: 'register_nasabah'),
    );
    when(() => dataSource.registerNasabah(
        const RegisterNasabahRequest(bankSampahId: 'bank-1'))).thenAnswer(
      (_) async => const OnboardingResult(nextStep: 'nasabah_dashboard'),
    );

    await pump(tester, pushed: true);

    await tester.tap(find.text('Tap untuk pilih bank sampah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank Sampah BTH'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajukan Pendaftaran'));
    await tester.pumpAndSettle();

    verifyInOrder([
      () => dataSource.completeProfile(_draft),
      () => dataSource.registerNasabah(
          const RegisterNasabahRequest(bankSampahId: 'bank-1')),
    ]);
    expect(find.text('NASABAH DASHBOARD'), findsOneWidget);
  });

  group('existing membership lock', () {
    testWidgets('shows the joined bank sampah and its status', (tester) async {
      when(() => dataSource.listMyMemberships())
          .thenAnswer((_) async => [_joinedMembership]);

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('Bank Sampah Lama'), findsOneWidget);
      expect(find.textContaining('hanya dapat terdaftar di 1 bank sampah'),
          findsOneWidget);
    });

    testWidgets('locks the picker so it no longer opens', (tester) async {
      when(() => dataSource.listMyMemberships())
          .thenAnswer((_) async => [_joinedMembership]);

      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap untuk pilih bank sampah'));
      await tester.pumpAndSettle();

      expect(find.text('Cari nama bank sampah...'), findsNothing);
    });

    testWidgets(
        'submitting while locked lands the profile without a new '
        'registration', (tester) async {
      // Realistic shape of this state: the pengurus-entered record already
      // linked at login, before the profile draft banked on step one was
      // ever sent — there is no route to this screen, locked, without one.
      onboarding.saveProfileDraft(_draft);
      when(() => dataSource.listMyMemberships())
          .thenAnswer((_) async => [_joinedMembership]);
      when(() => dataSource.completeProfile(_draft)).thenAnswer(
          (_) async => const OnboardingResult(nextStep: 'nasabah_dashboard'));

      await pump(tester, pushed: true);
      await tester.pumpAndSettle();

      expect(find.text('Ajukan Pendaftaran'), findsNothing);
      await tester.ensureVisible(find.text('Lanjutkan'));
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      verify(() => dataSource.completeProfile(_draft)).called(1);
      verifyNever(() => dataSource.registerNasabah(any()));
      expect(find.text('NASABAH DASHBOARD'), findsOneWidget);
    });

    testWidgets('leaves the picker open with no existing membership',
        (tester) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap untuk pilih bank sampah'));
      await tester.pumpAndSettle();

      expect(find.text('Cari nama bank sampah...'), findsOneWidget);
    });
  });

  group('leaving and failing', () {
    Future<void> pickBank(WidgetTester tester) async {
      await tester.tap(find.text('Tap untuk pilih bank sampah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Sampah BTH'));
      await tester.pumpAndSettle();
    }

    testWidgets('a rejected application shows the error and stays',
        (tester) async {
      when(() => dataSource.registerNasabah(any())).thenAnswer(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      await pump(tester);
      await pickBank(tester);

      await tester.tap(find.text('Ajukan Pendaftaran'));
      await pumpToast(tester);

      expect(find.text('Connection Timeout'), findsOneWidget);
      expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('the membership status label follows the status',
        (tester) async {
      for (final (status, active, label) in [
        ('pending', false, 'Menunggu'),
        ('rejected', false, 'Ditolak'),
        ('approved', false, 'Nonaktif'),
        ('approved', true, 'Aktif'),
      ]) {
        when(() => dataSource.listMyMemberships()).thenAnswer((_) async => [
              NasabahMembershipEntity(
                id: 'm',
                bankSampahId: 'b',
                bankSampahNama: 'Bank Lama',
                bankSampahKota: 'Bogor',
                status: status,
                isActive: active,
              ),
            ]);
        await pump(tester);
        await tester.pumpAndSettle();

        expect(find.text(label), findsOneWidget, reason: status);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a failed membership lookup leaves the form open',
        (tester) async {
      when(() => dataSource.listMyMemberships())
          .thenAnswer((_) async => throw StateError('offline'));

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
    });

    testWidgets('system back mid-wizard returns to the profile screen',
        (tester) async {
      onboarding.saveProfileDraft(_draft);
      await pump(tester, pushed: true);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('COMPLETE PROFILE'), findsOneWidget);
    });

    testWidgets('system back with nothing underneath goes to the profile form',
        (tester) async {
      onboarding.saveProfileDraft(_draft);
      await pump(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('COMPLETE PROFILE'), findsOneWidget);
    });

    testWidgets('system back when reached directly asks before leaving',
        (tester) async {
      await pump(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari Pendaftaran?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      verifyNever(() => auth.add(any(that: isA<LogoutRequested>())));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Keluar'));
      await tester.pumpAndSettle();
      verify(() => auth.add(any(that: isA<LogoutRequested>()))).called(1);
    });

    testWidgets('signing out routes to the login page', (tester) async {
      whenListen(
        auth,
        Stream<AuthenticationStates>.fromIterable([Unauthenticated()]),
        initialState: AuthenticationInitial(),
      );
      await pump(tester, extraRoutes: ['/login']);
      await tester.pumpAndSettle();

      expect(find.text('route:/login'), findsOneWidget);
    });
  });
}
