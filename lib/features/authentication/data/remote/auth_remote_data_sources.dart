import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/mapper/auth_mapper.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/post_login_request.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:injectable/injectable.dart';

import 'model/responses/auth_response.dart';

abstract class AuthRemoteDataSources {
  Future<AuthResponse> postLogin(PostLoginRequest request);
  Future<AuthResponse> loginWithGoogle(String idToken);

  /// Restores the current session from the persisted bearer token.
  Future<AuthEntity> getMe();

  /// Revokes [refreshToken] server-side (blacklists it).
  Future<void> logout(String refreshToken);
}

@LazySingleton(as: AuthRemoteDataSources)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSources {
  final NetworkService networkService;

  const AuthRemoteDataSourceImpl(this.networkService);

  @override
  Future<AuthResponse> postLogin(PostLoginRequest request) async {
    const url = Endpoints.login;
    final response = await networkService.post(url, data: request.toJson());
    return AuthResponse.fromJson(response.data);
  }

  @override
  Future<AuthResponse> loginWithGoogle(String idToken) async {
    final response = await networkService.post(
      Endpoints.loginWithGoogle,
      data: {'id_token': idToken},
    );
    return AuthResponse.fromJson(response.data);
  }

  @override
  Future<AuthEntity> getMe() async {
    final response = await networkService.get(Endpoints.authMe);
    return AuthMapper.mapMeResponseToDomain(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> logout(String refreshToken) async {
    await networkService.post(
      Endpoints.logout,
      data: {'refresh_token': refreshToken},
    );
  }
}
