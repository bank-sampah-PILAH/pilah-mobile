import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

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

  Future<GoRouter> pump(WidgetTester tester, {bool pushed = false}) async {
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
          path: '/nasabah-dashboard',
          builder: (_, __) => const Scaffold(body: Text('NASABAH DASHBOARD')),
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

      expect(find.text('Pilih Bank Sampah'), findsNothing);
    });

    testWidgets('disables submit so no registration can be sent',
        (tester) async {
      when(() => dataSource.listMyMemberships())
          .thenAnswer((_) async => [_joinedMembership]);

      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajukan Pendaftaran'));
      await tester.pumpAndSettle();

      verifyNever(() => dataSource.registerNasabah(any()));
    });

    testWidgets('leaves the picker open with no existing membership',
        (tester) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap untuk pilih bank sampah'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Bank Sampah'), findsOneWidget);
    });
  });
}
