import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/invite_gate_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/onboarding_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

const _routes = [
  '/dashboard',
  '/register-nasabah',
  '/pending-approval',
  '/register-bank-sampah',
];

AuthEntity _user({String? step, String? bankStatus}) => AuthEntity(
      id: 'u1',
      name: 'Siti',
      email: 'siti@x.test',
      photoUrl: '',
      token: 't',
      role: 'pengelola',
      nextStep: step,
      bankSampahStatus: bankStatus,
    );

void main() {
  late StubApi api;
  late InviteTokenStore store;
  late MockAuthBloc auth;

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  setUp(() {
    api = StubApi();
    store = InviteTokenStore();
    di.registerSingleton<InviteTokenStore>(store);
  });

  tearDown(() => di.unregister<InviteTokenStore>());

  Future<void> open(WidgetTester tester, AuthEntity user) async {
    auth = authBlocIn(Authenticated(authEntity: user));
    final cubit = buildOnboardingCubit(api);
    addTearDown(cubit.close);
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: auth),
          BlocProvider<OnboardingCubit>.value(value: cubit),
        ],
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        child: InviteGatePage(),
      ),
      extraRoutes: _routes,
    );
    await tester.pump();
    await pumpToast(tester);
  }

  testWidgets('without a token it falls back to the onboarding step',
      (tester) async {
    await open(tester, _user(step: 'register_nasabah'));

    expect(find.text('route:/register-nasabah'), findsOneWidget);
    expect(api.requests, isEmpty);
    await settleToasts(tester);
  });

  testWidgets('redeeming a fresh invite refreshes the user and joins',
      (tester) async {
    store.save('tok-1');
    api.on('POST', '/api/v1/invites/accept',
        json: {'next_step': 'dashboard', 'nama': 'Bank Melati'});

    await open(tester, _user(step: 'dashboard'));

    expect(find.text('route:/dashboard'), findsOneWidget);
    expect(find.text('Berhasil bergabung ke Bank Sampah Bank Melati'),
        findsOneWidget);
    verify(() => auth.add(any(that: isA<RefreshUserRequested>()))).called(1);
    expect(store.hasToken, isFalse);
    await settleToasts(tester);
  });

  testWidgets('an invite to the bank the account is already in says so',
      (tester) async {
    store.save('tok-1');
    api.on('POST', '/api/v1/invites/accept',
        json: {'outcome': 'already_member', 'next_step': 'dashboard'});

    await open(tester, _user(step: 'dashboard'));

    expect(find.text('route:/dashboard'), findsOneWidget);
    expect(
        find.text('Anda sudah terdaftar pada bank sampah ini'), findsOneWidget);
    verifyNever(() => auth.add(any(that: isA<RefreshUserRequested>())));
    await settleToasts(tester);
  });

  testWidgets('an account on a different bank keeps its own destination',
      (tester) async {
    store.save('tok-1');
    api.on('POST', '/api/v1/invites/accept',
        status: 400,
        json: {'error': 'Akun ini sudah tergabung dengan bank sampah'});

    await open(tester, _user(step: 'register_bank_sampah'));

    expect(find.text('route:/register-bank-sampah'), findsOneWidget);
    expect(find.text('Sudah Menjadi Pengelola'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a pending registration gets the under-review wording',
      (tester) async {
    store.save('tok-1');
    api.on('POST', '/api/v1/invites/accept',
        status: 400,
        json: {'error': 'Akun ini sudah tergabung dengan bank sampah'});

    await open(tester, _user(step: 'approval_pending'));

    expect(find.text('route:/pending-approval'), findsOneWidget);
    expect(find.text('Pengajuan Sedang Ditinjau'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an invalid link is reported with the backend wording',
      (tester) async {
    store.save('tok-1');
    api.on('POST', '/api/v1/invites/accept',
        status: 400, json: {'error': 'Tautan undangan tidak valid'});

    await open(tester, _user(step: 'dashboard', bankStatus: 'active'));

    expect(find.text('Tautan Undangan'), findsOneWidget);
    expect(find.text('Tautan undangan tidak valid'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an unreachable server is reported as a failed join',
      (tester) async {
    store.save('tok-1');
    api.fail('POST', '/api/v1/invites/accept');

    await open(tester, _user(step: 'dashboard'));

    expect(find.text('Gagal Bergabung'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an unauthenticated visitor with no token still resolves',
      (tester) async {
    auth = authBlocIn(Unauthenticated());
    final cubit = buildOnboardingCubit(api);
    addTearDown(cubit.close);
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: auth),
          BlocProvider<OnboardingCubit>.value(value: cubit),
        ],
        child: const InviteGatePage(),
      ),
      extraRoutes: _routes,
    );
    await tester.pump();

    expect(find.text('route:/dashboard'), findsOneWidget);
  });
}
