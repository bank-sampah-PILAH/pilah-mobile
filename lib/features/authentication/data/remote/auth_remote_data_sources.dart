import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/post_login_request.dart';
import 'package:injectable/injectable.dart';

import 'model/responses/auth_response.dart';

abstract class AuthRemoteDataSources {
  Future<AuthResponse> postLogin(PostLoginRequest request);
  Future<AuthResponse> loginWithGoogle(String idToken);
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
    // TODO: Replace with actual API call once backend is ready.
    // e.g.: final response = await networkService.post(
    //   Endpoints.loginWithGoogle,
    //   data: {'idToken': idToken},
    // );
    // return AuthResponse.fromJson(response.data);

    // Mock implementation for UI testing
    await Future.delayed(const Duration(seconds: 2));
    return const AuthResponse(
      id: 1,
      username: 'google_user',
      email: 'user@gmail.com',
      firstName: 'Google',
      lastName: 'User',
      gender: '',
      image: 'https://lh3.googleusercontent.com/a/default-user',
      accessToken: 'mock_jwt_token_from_backend',
      refreshToken: 'mock_refresh_token',
      name: 'Google User',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user',
    );
  }
}
