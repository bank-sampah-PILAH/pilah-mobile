import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/data/local/auth_local_data_sources.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/mapper/auth_mapper.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/post_login_request.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/save_token_request.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/responses/auth_response.dart';
import 'package:pilah_mobile/features/authentication/data/remote/auth_remote_data_sources.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSources _remoteDataSources;
  final AuthLocalDataSources _localDataSources;

  const AuthRepositoryImpl(
    this._remoteDataSources,
    this._localDataSources,
  );

  Future<AuthEntity> _persistGoogleSession(Map<String, dynamic> payload) async {
    final response = AuthResponse.fromJson(payload);
    final entity = AuthMapper.mapResponseToDomain(response);
    await _localDataSources.saveToken(
      SaveTokenRequest(
        accessToken: entity.token,
        refreshToken: response.refreshToken,
      ),
    );
    return entity;
  }

  @override
  Future<Either<NetworkException, AuthEntity>> postLogin(
    String username,
    String password,
  ) async {
    final request = PostLoginRequest(username: username, password: password);
    return apiCall<AuthEntity>(
      func: _remoteDataSources.postLogin(request),
      mapper: (value) => AuthMapper.mapResponseToDomain(value),
    );
  }

  @override
  Future<Either<NetworkException, GoogleAuthOutcome>> loginWithGoogle(
      String idToken) async {
    try {
      final payload = await _remoteDataSources.loginWithGoogle(idToken);
      if (payload['registration_required'] == true) {
        final profile = payload['google_profile'] as Map<String, dynamic>? ??
            <String, dynamic>{};
        return Right(GoogleRegistrationRequired(
          registrationToken: payload['registration_token']?.toString() ?? '',
          expiresIn: (payload['expires_in'] as num?)?.toInt() ?? 600,
          name: profile['name']?.toString() ?? '',
          email: profile['email']?.toString() ?? '',
          photoUrl: profile['picture']?.toString() ?? '',
        ));
      }
      final entity = await _persistGoogleSession(payload);
      return Right(GoogleSession(entity));
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    } catch (e) {
      // Parse failures from AuthMapper / AuthResponse.fromJson on a malformed
      // 2xx body throw a TypeError/CastError — a Dart Error, not an Exception —
      // which the guard above would miss, crashing the login screen. Catch it
      // here and surface it like any other failure instead.
      return Left(GeneralException(message: e.toString()));
    }
  }

  @override
  Future<Either<NetworkException, AuthEntity>> registerGoogleUser({
    required String registrationToken,
    required GoogleRegistrationRole role,
  }) async {
    try {
      final payload = await _remoteDataSources.registerGoogleUser(
        registrationToken,
        role.wireValue,
      );
      final entity = await _persistGoogleSession(payload);
      return Right(entity);
    } on Exception catch (error) {
      return Left(NetworkException.handleException(error));
    } catch (error) {
      return Left(GeneralException(message: error.toString()));
    }
  }

  @override
  Future<Either<Exception, void>> saveToken(
      String accessToken, String refreshToken) async {
    try {
      final request = SaveTokenRequest(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _localDataSources.saveToken(request);
      return const Right(null);
    } catch (e) {
      return Left(e as Exception);
    }
  }

  @override
  Future<Either<NetworkException, AuthEntity>> getMe() {
    return apiCall<AuthEntity>(
      func: _remoteDataSources.getMe(),
      mapper: (value) => value as AuthEntity,
    );
  }

  @override
  Future<Either<NetworkException, void>> logout() async {
    // Best effort: revoke the refresh token server-side, but never block the
    // local sign-out on a network failure (expired token, offline, etc.).
    try {
      final refreshToken = await _localDataSources.readRefreshToken() ?? '';
      if (refreshToken.isNotEmpty) {
        await _remoteDataSources.logout(refreshToken);
      }
    } catch (_) {
      // Ignore — the token is cleared locally regardless.
    }
    await _localDataSources.clearToken();
    return const Right(null);
  }

  @override
  Future<bool> hasSession() async {
    final token = await _localDataSources.readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
