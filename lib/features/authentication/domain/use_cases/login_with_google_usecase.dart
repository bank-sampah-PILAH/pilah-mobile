import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/bases/use_case.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart';

@lazySingleton
class LoginWithGoogleUseCase extends UseCase<GoogleAuthOutcome, String> {
  final AuthRepository _repository;

  LoginWithGoogleUseCase(this._repository);

  @override
  Future<Either<NetworkException, GoogleAuthOutcome?>> execute([String? args]) {
    return _repository.loginWithGoogle(args ?? '');
  }

  Future<Either<NetworkException, AuthEntity>> register({
    required String registrationToken,
    required GoogleRegistrationRole role,
  }) {
    return _repository.registerGoogleUser(
      registrationToken: registrationToken,
      role: role,
    );
  }
}
