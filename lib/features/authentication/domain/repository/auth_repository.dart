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

  Future<Either<Exception, void>> saveToken(
    String accessToken,
    String refreshToken,
  );

  /// Restores the session from `GET /auth/me` using the persisted bearer token.
  Future<Either<NetworkException, AuthEntity>> getMe();

  /// Revokes the refresh token server-side (best effort) and clears the local
  /// session. Always succeeds locally even if the network call fails.
  Future<Either<NetworkException, void>> logout();

  /// Deletes the signed-in profile-incomplete account so registration can
  /// restart with a different role. Fails (Left) when the account has
  /// committed data the backend refuses to discard.
  Future<Either<NetworkException, void>> discardRegistration();

  /// Whether a bearer token is currently persisted on the device.
  Future<bool> hasSession();
}
