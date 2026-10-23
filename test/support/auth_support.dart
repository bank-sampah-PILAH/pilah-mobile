import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

class TestAuthenticationNotifier extends AuthenticationNotifier {
  TestAuthenticationNotifier({
    AuthenticationStates? initialState,
  })  : _initialState = initialState ?? AuthenticationInitial(),
        super(_NoopAuthenticationUseCases(), _NoopLoginWithGoogleUseCase());

  AuthenticationStates _initialState;
  bool _active = false;
  final calls = <String>[];
  String? lastEmail;
  String? lastPassword;
  String? lastIdToken;
  GoogleRegistrationRole? lastRole;

  @override
  AuthenticationStates build() {
    _active = true;
    ref.onDispose(() => _active = false);
    return _initialState;
  }

  void setStateForTest(AuthenticationStates next) {
    _initialState = next;
    if (_active) state = next;
  }

  @override
  Future<void> postLogin(String email, String password) async {
    calls.add('postLogin');
    lastEmail = email;
    lastPassword = password;
  }

  @override
  void refreshLogin() => calls.add('refreshLogin');

  @override
  Future<void> loginWithGoogle(String idToken) async {
    calls.add('loginWithGoogle');
    lastIdToken = idToken;
  }

  @override
  Future<void> registerGoogleRole(GoogleRegistrationRole role) async {
    calls.add('registerGoogleRole');
    lastRole = role;
  }

  @override
  Future<void> changeGoogleAccount() async {
    calls.add('changeGoogleAccount');
    setStateForTest(AuthenticationInitial());
  }

  @override
  Future<void> checkSession() async {
    calls.add('checkSession');
    final initialState = _initialState;
    setStateForTest(AuthenticationLoading());
    setStateForTest(initialState);
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    setStateForTest(Unauthenticated());
  }

  @override
  Future<void> refreshUser() async => calls.add('refreshUser');
}

class _NoopAuthenticationUseCases implements AuthenticationUseCases {
  @override
  Future<bool> hasSession() async => false;

  @override
  Future<Either<NetworkException, AuthEntity>> getMe() async =>
      Left(GeneralException(message: 'No test session'));

  @override
  Future<Either<NetworkException, AuthEntity>> postLogin(
          String email, String password) async =>
      Left(GeneralException(message: 'Not configured'));

  @override
  Future<Either<NetworkException, void>> logout() async => const Right(null);

  @override
  Future<Either<Exception, void>> saveToken(
          String accessToken, String refreshToken) async =>
      const Right(null);
}

class _NoopLoginWithGoogleUseCase extends LoginWithGoogleUseCase {
  _NoopLoginWithGoogleUseCase() : super(_NoopAuthRepository());
}

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<Either<NetworkException, GoogleAuthOutcome>> loginWithGoogle(
          String idToken) async =>
      Left(GeneralException(message: 'Not configured'));

  @override
  Future<Either<NetworkException, AuthEntity>> postLogin(
          String email, String password) async =>
      Left(GeneralException(message: 'Not configured'));

  @override
  Future<Either<NetworkException, AuthEntity>> registerGoogleUser({
    required String registrationToken,
    required GoogleRegistrationRole role,
  }) async =>
      Left(GeneralException(message: 'Not configured'));

  @override
  Future<Either<NetworkException, void>> logout() async => const Right(null);

  @override
  Future<Either<Exception, void>> saveToken(
          String accessToken, String refreshToken) async =>
      const Right(null);

  @override
  Future<Either<NetworkException, AuthEntity>> getMe() async =>
      Left(GeneralException(message: 'Not configured'));

  @override
  Future<bool> hasSession() async => false;
}

AuthEntity testAuth({
  String name = 'Siti Aminah',
  String? bank = 'Bank Sampah Melati',
  String? role = 'pengelola',
}) =>
    AuthEntity(
      id: 'u1',
      name: name,
      email: 'siti@example.test',
      photoUrl: '',
      token: 'tok',
      bankSampahNama: bank,
      role: role,
    );

TestAuthenticationNotifier authNotifierIn(AuthenticationStates state) =>
    TestAuthenticationNotifier(initialState: state);

Widget withAuthenticationProvider(
  TestAuthenticationNotifier notifier,
  Widget child,
) =>
    ProviderScope(
      overrides: [authenticationProvider.overrideWith(() => notifier)],
      child: child,
    );
