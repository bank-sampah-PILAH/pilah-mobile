import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<NetworkException, AuthEntity>> postLogin(
    String username,
    String password,
  );

  Future<Either<NetworkException, AuthEntity>> loginWithGoogle(String idToken);

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
