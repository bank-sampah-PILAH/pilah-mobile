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
}
