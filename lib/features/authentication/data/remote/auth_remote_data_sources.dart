import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/mapper/auth_mapper.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/post_login_request.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:injectable/injectable.dart';

import 'model/responses/auth_response.dart';

abstract class AuthRemoteDataSources {
  Future<AuthResponse> postLogin(PostLoginRequest request);
  Future<Map<String, dynamic>> loginWithGoogle(String idToken);
  Future<Map<String, dynamic>> registerGoogleUser(
      String registrationToken, String role);

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
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await networkService.post(
      Endpoints.loginWithGoogle,
      data: {'id_token': idToken},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> registerGoogleUser(
      String registrationToken, String role) async {
    final response = await networkService.post(
      Endpoints.registerGoogleUser,
      data: {'registration_token': registrationToken, 'role': role},
    );
    return response.data as Map<String, dynamic>;
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
