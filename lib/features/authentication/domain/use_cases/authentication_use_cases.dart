import 'package:dartz/dartz.dart';

import '../../../../core/client/network_exception.dart';
import '../model/auth.dart';

abstract class AuthenticationUseCases {
  Future<Either<NetworkException, AuthEntity>> postLogin(
    String email,
    String password,
  );

  Future<Either<Exception, void>> saveToken(
    String accessToken,
    String refreshToken,
  );

  Future<Either<NetworkException, AuthEntity>> getMe();

  Future<Either<NetworkException, void>> logout();

  /// Deletes the signed-in profile-incomplete account so registration can
  /// restart with a different role.
  Future<Either<NetworkException, void>> discardRegistration();

  Future<bool> hasSession();
}
