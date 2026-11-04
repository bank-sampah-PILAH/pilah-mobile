import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

/// Supplies an explicitly offline authenticated session to the preview app.
class PreviewAuthenticationNotifier extends AuthenticationNotifier {
  PreviewAuthenticationNotifier(PreviewAuthenticationSession session)
      : super(session, LoginWithGoogleUseCase(session));

  @override
  AuthenticationStates build() =>
      Authenticated(authEntity: PreviewAuthenticationSession.auth);
}

PreviewAuthenticationNotifier createPreviewAuthenticationNotifier() =>
    PreviewAuthenticationNotifier(PreviewAuthenticationSession());

class PreviewAuthenticationSession
    implements AuthenticationUseCases, AuthRepository {
  static const auth = AuthEntity(
    id: 'preview-nasabah',
    name: 'Siti Aminah',
    email: 'preview@example.test',
    photoUrl: '',
    token: '',
    role: 'nasabah',
    nextStep: 'dashboard',
    bankSampahStatus: 'active',
    bankSampahNama: 'Bank Sampah Melati',
  );

  bool _hasSession = true;

  @override
  Future<bool> hasSession() async => _hasSession;

  @override
  Future<Either<NetworkException, AuthEntity>> getMe() async =>
      const Right(auth);

  @override
  Future<Either<NetworkException, AuthEntity>> postLogin(
      String username, String password) async {
    _hasSession = true;
    return const Right(auth);
  }

  @override
  Future<Either<NetworkException, GoogleAuthOutcome>> loginWithGoogle(
      String idToken) async {
    _hasSession = true;
    return const Right(GoogleSession(auth));
  }

  @override
  Future<Either<NetworkException, AuthEntity>> registerGoogleUser({
    required String registrationToken,
    required GoogleRegistrationRole role,
  }) async {
    _hasSession = true;
    return const Right(auth);
  }

  @override
  Future<Either<NetworkException, AuthEntity>> changeRole(
      GoogleRegistrationRole role) async {
    _hasSession = true;
    return const Right(auth);
  }

  @override
  Future<Either<Exception, void>> saveToken(
          String accessToken, String refreshToken) async =>
      const Right(null);

  @override
  Future<Either<NetworkException, void>> logout() async {
    _hasSession = false;
    return const Right(null);
  }
}
