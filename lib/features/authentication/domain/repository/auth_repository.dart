import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<NetworkException, AuthEntity>> postLogin(
    String email,
    String password,
  );

  Future<Either<NetworkException, GoogleAuthOutcome>> loginWithGoogle(
      String idToken);

  Future<Either<NetworkException, AuthEntity>> registerGoogleUser({
    required String registrationToken,
    required GoogleRegistrationRole role,
  });

  /// Switches a registering account's role while onboarding has not committed
  /// anything for it, and keeps the session the backend issues for the new
  /// role. A refusal leaves the stored session as it was.
  Future<Either<NetworkException, AuthEntity>> changeRole(
      GoogleRegistrationRole role);

  Future<Either<Exception, void>> saveToken(
    String accessToken,
    String refreshToken,
  );

  /// Restores the session from `GET /auth/me` using the persisted bearer token.
  Future<Either<NetworkException, AuthEntity>> getMe();

  /// Revokes the refresh token server-side (best effort) and clears the local
  /// session. Always succeeds locally even if the network call fails.
  Future<Either<NetworkException, void>> logout();

  /// Whether a bearer token is currently persisted on the device.
  Future<bool> hasSession();
}
