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

const _bank = BankSampahDirectoryEntity(
  id: 'bank-1',
  nama: 'Bank Sampah BTH',
  alamat: 'Kel. Kukusan',
  kota: 'Depok',
  fotoLogo: '',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRegisterNasabahRequest());
    registerFallbackValue(_FakeAuthEvent());
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
  });

  tearDown(() => onboarding.close());

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: RegisterNasabahScreen.route,
      routes: [
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
  }

  testWidgets('submits the picked bank and address, then routes onward',
      (tester) async {
    when(() => dataSource.registerNasabah(const RegisterNasabahRequest(
          bankSampahId: 'bank-1',
          alamat: 'Jl. Melati No. 5',
        ))).thenAnswer(
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

    await tester.enterText(
      find.byType(TextFormField),
      'Jl. Melati No. 5',
    );

    await tester.tap(find.text('Ajukan Pendaftaran'));
    await tester.pumpAndSettle();

    verify(() => dataSource.registerNasabah(const RegisterNasabahRequest(
          bankSampahId: 'bank-1',
          alamat: 'Jl. Melati No. 5',
        ))).called(1);
    verify(() => auth.add(
          any<AuthenticationEvent>(that: isA<RefreshUserRequested>()),
        )).called(1);
    expect(find.text('NASABAH DASHBOARD'), findsOneWidget);
  });

  testWidgets('blocks submit and shows an inline error with no bank picked',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField), 'Jl. Melati No. 5');
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await tester.pumpAndSettle();

    expect(find.text('Bank sampah wajib dipilih'), findsOneWidget);
    verifyNever(() => dataSource.registerNasabah(any()));
  });
}
