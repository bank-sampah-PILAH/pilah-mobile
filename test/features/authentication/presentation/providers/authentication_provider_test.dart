import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

class _MockAuthenticationUseCases extends Mock
    implements AuthenticationUseCases {}

class _MockLoginWithGoogleUseCase extends Mock
    implements LoginWithGoogleUseCase {}

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

class _Harness {
  _Harness(
    this.useCases,
    this.googleUseCase, {
    AuthenticationStates? initialState,
    bool isWeb = false,
  }) {
    notifier = _TestAuthenticationNotifier(
      useCases,
      googleUseCase,
      initialState: initialState ?? AuthenticationInitial(),
      isWeb: isWeb,
    );
    container = ProviderContainer(
      overrides: [authenticationProvider.overrideWith(() => notifier)],
    );
    container.read(authenticationProvider);
    subscription = container.listen(authenticationProvider, (_, next) {
      states.add(next);
    });
  }

  final AuthenticationUseCases useCases;
  final LoginWithGoogleUseCase googleUseCase;
  final states = <AuthenticationStates>[];
  late final _TestAuthenticationNotifier notifier;
  late final ProviderContainer container;
  late final ProviderSubscription<AuthenticationStates> subscription;

  void seed(AuthenticationStates state) {
    notifier.setState(state);
    states.clear();
  }

  void close() {
    subscription.close();
    container.dispose();
  }
}

class _TestAuthenticationNotifier extends AuthenticationNotifier {
  // ignore: use_super_parameters
  _TestAuthenticationNotifier(
    AuthenticationUseCases useCases,
    LoginWithGoogleUseCase googleUseCase, {
    required this.initialState,
    required bool isWeb,
  }) : super(useCases, googleUseCase, isWebOverride: isWeb);

  final AuthenticationStates initialState;

  @override
  AuthenticationStates build() => initialState;

  void setState(AuthenticationStates next) => state = next;
}

void main() {
  late _MockAuthenticationUseCases useCases;
  late _MockLoginWithGoogleUseCase googleUseCase;
  late _Harness harness;

  const auth = AuthEntity(
    id: '1',
    name: 'Test User',
    email: 'test@example.com',
    photoUrl: '',
    token: 'access_token',
  );
  const registration = GoogleRegistrationRequired(
    registrationToken: 'signed-token',
    expiresIn: 600,
    name: 'Test User',
    email: 'test@example.com',
    photoUrl: '',
  );

  setUp(() {
    useCases = _MockAuthenticationUseCases();
    googleUseCase = _MockLoginWithGoogleUseCase();
    harness = _Harness(useCases, googleUseCase);
  });

  tearDown(() => harness.close());

  test('starts in AuthenticationInitial', () {
    expect(harness.container.read(authenticationProvider),
        isA<AuthenticationInitial>());
  });

  test('password login emits loading then authenticated', () async {
    when(() => useCases.postLogin('test@example.com', 'password'))
        .thenAnswer((_) async => const Right(auth));

    await harness.notifier.postLogin('test@example.com', 'password');

    expect(harness.states,
        [AuthenticationLoading(), Authenticated(authEntity: auth)]);
    verify(() => useCases.postLogin('test@example.com', 'password')).called(1);
  });

  test('password login failure is shown', () async {
    when(() => useCases.postLogin('test@example.com', 'bad')).thenAnswer(
        (_) async => Left(GeneralException(message: 'Login failed')));

    await harness.notifier.postLogin('test@example.com', 'bad');

    expect(harness.states, [
      AuthenticationLoading(),
      AuthenticationFailure(message: 'Login failed'),
    ]);
  });

  test('switching email accounts clears old session first', () async {
    harness.seed(Authenticated(
      authEntity: const AuthEntity(
        id: 'previous',
        name: 'Previous',
        email: 'previous@example.com',
        photoUrl: '',
        token: 'old-token',
      ),
    ));
    when(() => useCases.postLogin('test@example.com', 'password'))
        .thenAnswer((_) async => const Right(auth));

    await harness.notifier.postLogin('test@example.com', 'password');

    expect(harness.states, [
      AuthenticationLoading(),
      Unauthenticated(),
      Authenticated(authEntity: auth),
    ]);
  });

  test('same-account login keeps its existing session', () async {
    harness.seed(Authenticated(
      authEntity: const AuthEntity(
        id: '1',
        name: 'Old name',
        email: 'TEST@example.com',
        photoUrl: '',
        token: 'old-token',
      ),
    ));
    when(() => useCases.postLogin('test@example.com', 'password'))
        .thenAnswer((_) async => const Right(auth));

    await harness.notifier.postLogin('test@example.com', 'password');

    expect(harness.states, [
      AuthenticationLoading(),
      Authenticated(authEntity: auth),
    ]);
  });

  test('a failed account switch retains the old identity for retry', () async {
    harness.seed(Authenticated(
      authEntity: const AuthEntity(
        id: 'previous',
        name: 'Previous',
        email: 'previous@example.com',
        photoUrl: '',
        token: 'old-token',
      ),
    ));
    when(() => useCases.postLogin('new@example.com', 'bad')).thenAnswer(
      (_) async => Left(GeneralException(message: 'Login failed')),
    );
    when(() => useCases.postLogin('test@example.com', 'password'))
        .thenAnswer((_) async => const Right(auth));

    await harness.notifier.postLogin('new@example.com', 'bad');
    await harness.notifier.postLogin('test@example.com', 'password');

    expect(harness.states, [
      AuthenticationLoading(),
      AuthenticationFailure(message: 'Login failed'),
      AuthenticationLoading(),
      Unauthenticated(),
      Authenticated(authEntity: auth),
    ]);
  });

  test('login refresh clears only login errors', () {
    harness.seed(AuthenticationFailure(message: 'bad login'));
    harness.notifier.refreshLogin();
    expect(harness.container.read(authenticationProvider),
        isA<AuthenticationInitial>());

    harness.states.clear();
    harness.notifier.refreshLogin();
    expect(harness.states, isEmpty);
  });

  test('Google session authenticates the account', () async {
    when(() => googleUseCase.execute('google-token'))
        .thenAnswer((_) async => const Right(GoogleSession(auth)));

    await harness.notifier.loginWithGoogle('google-token');

    expect(harness.states, [
      AuthenticationLoading(),
      Authenticated(authEntity: auth),
    ]);
  });

  test('Google registration is held for role selection', () async {
    when(() => googleUseCase.execute('google-token'))
        .thenAnswer((_) async => const Right(registration));

    await harness.notifier.loginWithGoogle('google-token');

    expect(harness.states, [
      AuthenticationLoading(),
      GoogleRegistrationPending(registration: registration),
    ]);
  });

  test('Google login reports missing messages and invalid outcomes', () async {
    when(() => googleUseCase.execute('no-message'))
        .thenAnswer((_) async => Left(NetworkException()));
    when(() => googleUseCase.execute('invalid'))
        .thenAnswer((_) async => const Right(null));

    await harness.notifier.loginWithGoogle('no-message');
    expect(harness.states.last,
        AuthenticationFailure(message: 'Unknown error occurred'));
    await harness.notifier.loginWithGoogle('invalid');
    expect(harness.states.last,
        AuthenticationFailure(message: 'Invalid response from server'));
  });

  test('role submission authenticates the selected role', () async {
    harness.seed(GoogleRegistrationPending(registration: registration));
    when(() => googleUseCase.register(
          registrationToken: 'signed-token',
          role: GoogleRegistrationRole.nasabah,
        )).thenAnswer((_) async => const Right(auth));

    await harness.notifier.registerGoogleRole(GoogleRegistrationRole.nasabah);

    expect(harness.states, [
      GoogleRegistrationSubmitting(
        registration: registration,
        role: GoogleRegistrationRole.nasabah,
      ),
      Authenticated(authEntity: auth),
    ]);
  });

  test('role submission failure retains registration so it can be retried',
      () async {
    harness.seed(GoogleRegistrationPending(registration: registration));
    when(() => googleUseCase.register(
          registrationToken: 'signed-token',
          role: GoogleRegistrationRole.pengelola,
        )).thenAnswer(
      (_) async => Left(GeneralException(message: 'Network failed')),
    );
    when(() => googleUseCase.register(
          registrationToken: 'signed-token',
          role: GoogleRegistrationRole.nasabah,
        )).thenAnswer((_) async => const Right(auth));

    await harness.notifier.registerGoogleRole(GoogleRegistrationRole.pengelola);
    expect(
        harness.states.last,
        GoogleRegistrationFailure(
            registration: registration, message: 'Network failed'));
    await harness.notifier.registerGoogleRole(GoogleRegistrationRole.nasabah);
    expect(harness.states.last, Authenticated(authEntity: auth));
  });

  for (final code in [
    'registration_token_expired',
    'registration_token_invalid',
  ]) {
    test('expired role token `$code` is reported distinctly', () async {
      harness.seed(GoogleRegistrationPending(registration: registration));
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/auth/google/register'),
        data: {'code': code},
        statusCode: 400,
      );
      when(() => googleUseCase.register(
            registrationToken: 'signed-token',
            role: GoogleRegistrationRole.nasabah,
          )).thenAnswer((_) async => Left(BadRequestException(
            response: response,
            message: 'Sesi pendaftaran kedaluwarsa',
          )));

      await harness.notifier.registerGoogleRole(GoogleRegistrationRole.nasabah);

      expect(harness.states.last,
          GoogleRegistrationExpired(message: 'Sesi pendaftaran kedaluwarsa'));
    });
  }

  test('role submission is ignored without pending registration', () async {
    await harness.notifier.registerGoogleRole(GoogleRegistrationRole.nasabah);
    expect(harness.states, isEmpty);
  });

  test('changing account disconnects Google and clears pending registration',
      () async {
    final original = google_sign_in.GoogleSignInPlatform.instance;
    final platform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = platform;
    when(() => platform.disconnect(const google_sign_in.DisconnectParams()))
        .thenAnswer((_) async {});
    harness.seed(GoogleRegistrationPending(registration: registration));
    addTearDown(() => google_sign_in.GoogleSignInPlatform.instance = original);

    await harness.notifier.changeGoogleAccount();

    expect(harness.container.read(authenticationProvider),
        isA<AuthenticationInitial>());
    verify(() => platform.disconnect(const google_sign_in.DisconnectParams()))
        .called(1);
  });

  test('changing account still clears app state if Google disconnect fails',
      () async {
    final original = google_sign_in.GoogleSignInPlatform.instance;
    final platform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = platform;
    when(() => platform.disconnect(const google_sign_in.DisconnectParams()))
        .thenAnswer((_) async => throw StateError('GIS unavailable'));
    harness.seed(GoogleRegistrationPending(registration: registration));
    addTearDown(() => google_sign_in.GoogleSignInPlatform.instance = original);

    await harness.notifier.changeGoogleAccount();

    expect(harness.container.read(authenticationProvider),
        isA<AuthenticationInitial>());
  });

  test('session restore without a token ends unauthenticated', () async {
    when(() => useCases.hasSession()).thenAnswer((_) async => false);

    await harness.notifier.checkSession();

    expect(harness.states, [AuthenticationLoading(), Unauthenticated()]);
    verifyNever(() => useCases.getMe());
  });

  test('session restore validates and accepts a persisted user', () async {
    when(() => useCases.hasSession()).thenAnswer((_) async => true);
    when(() => useCases.getMe()).thenAnswer((_) async => const Right(auth));

    await harness.notifier.checkSession();

    expect(harness.states,
        [AuthenticationLoading(), Authenticated(authEntity: auth)]);
  });

  test('session restore drops an expired token', () async {
    when(() => useCases.hasSession()).thenAnswer((_) async => true);
    when(() => useCases.getMe())
        .thenAnswer((_) async => Left(GeneralException(message: 'expired')));
    when(() => useCases.logout()).thenAnswer((_) async => const Right(null));

    await harness.notifier.checkSession();

    expect(harness.states, [AuthenticationLoading(), Unauthenticated()]);
    verify(() => useCases.logout()).called(1);
  });

  test('refresh user keeps the current session when fetch fails', () async {
    harness.seed(Authenticated(authEntity: auth));
    when(() => useCases.getMe())
        .thenAnswer((_) async => Left(GeneralException(message: 'offline')));

    await harness.notifier.refreshUser();

    expect(harness.states, isEmpty);
    expect(harness.container.read(authenticationProvider),
        Authenticated(authEntity: auth));
  });

  test('refresh user replaces the cached session on success', () async {
    harness.seed(Authenticated(authEntity: auth));
    const updated = AuthEntity(
      id: '1',
      name: 'Updated User',
      email: 'test@example.com',
      photoUrl: '',
      token: 'access_token',
    );
    when(() => useCases.getMe()).thenAnswer((_) async => const Right(updated));

    await harness.notifier.refreshUser();

    expect(harness.container.read(authenticationProvider),
        Authenticated(authEntity: updated));
  });

  test('native logout emits loading then unauthenticated', () async {
    when(() => useCases.logout()).thenAnswer((_) async => const Right(null));

    await harness.notifier.logout();

    expect(harness.states, [AuthenticationLoading(), Unauthenticated()]);
  });

  test('web logout signs out of Google before clearing PILAH session',
      () async {
    final original = google_sign_in.GoogleSignInPlatform.instance;
    final platform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = platform;
    final signOut = Completer<void>();
    final calls = <String>[];
    when(() => platform.signOut(const google_sign_in.SignOutParams()))
        .thenAnswer((_) {
      calls.add('Google sign-out');
      return signOut.future;
    });
    when(() => useCases.logout()).thenAnswer((_) async {
      calls.add('PILAH logout');
      return const Right(null);
    });
    final webHarness = _Harness(useCases, googleUseCase, isWeb: true);
    addTearDown(webHarness.close);
    addTearDown(() => google_sign_in.GoogleSignInPlatform.instance = original);

    final logout = webHarness.notifier.logout();
    expect(webHarness.states, [AuthenticationLoading()]);
    expect(calls, ['Google sign-out']);
    signOut.complete();
    await logout;

    expect(calls, ['Google sign-out', 'PILAH logout']);
    expect(webHarness.states.last, isA<Unauthenticated>());
  });

  test('web logout proceeds if Google sign-out fails', () async {
    final original = google_sign_in.GoogleSignInPlatform.instance;
    final platform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = platform;
    when(() => platform.signOut(const google_sign_in.SignOutParams()))
        .thenAnswer((_) async => throw StateError('GIS unavailable'));
    when(() => useCases.logout()).thenAnswer((_) async => const Right(null));
    final webHarness = _Harness(useCases, googleUseCase, isWeb: true);
    addTearDown(webHarness.close);
    addTearDown(() => google_sign_in.GoogleSignInPlatform.instance = original);

    await webHarness.notifier.logout();

    expect(webHarness.states, [AuthenticationLoading(), Unauthenticated()]);
    verify(() => useCases.logout()).called(1);
  });

  test('a pending login result is ignored after provider disposal', () async {
    final response = Completer<Either<NetworkException, AuthEntity>>();
    when(() => useCases.postLogin('test@example.com', 'password'))
        .thenAnswer((_) => response.future);
    final pending = harness.notifier.postLogin('test@example.com', 'password');
    expect(harness.states, [AuthenticationLoading()]);
    harness.close();
    response.complete(const Right(auth));

    await pending;
    expect(harness.states, [AuthenticationLoading()]);
  });
}
