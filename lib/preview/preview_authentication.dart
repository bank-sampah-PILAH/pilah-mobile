import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/check_session_events.dart';

/// Uses the production event handlers with an explicitly offline session.
/// Only the preview entrypoint creates this; it is never registered in app DI.
AuthenticationBloc createPreviewAuthenticationBloc() {
  final session = PreviewAuthenticationSession();
  return AuthenticationBloc(session, LoginWithGoogleUseCase(session))
    ..add(CheckSessionRequested());
}

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
  Future<Either<NetworkException, AuthEntity>> loginWithGoogle(
      String idToken) async {
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
