import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/save_token_request.dart';
import 'package:injectable/injectable.dart';

abstract class AuthLocalDataSources {
  Future<void> saveToken(SaveTokenRequest request);

  /// Removes both tokens from secure storage and clears the in-memory session.
  Future<void> clearToken();

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();
}

@LazySingleton(as: AuthLocalDataSources)
class AuthLocalDataSourcesImpl implements AuthLocalDataSources {
  final SecureDatabase _database;
  final NetworkUtils _networkUtils;

  const AuthLocalDataSourcesImpl(this._database, this._networkUtils);

  @override
  Future<void> saveToken(SaveTokenRequest request) async {
    await _database.write(
      key: AppKey.token,
      value: request.accessToken,
    );
    await _database.write(
      key: AppKey.refreshToken,
      value: request.refreshToken,
    );
    await _networkUtils.setToken(
      accessToken: request.accessToken,
      refreshToken: request.refreshToken,
    );
  }

  @override
  Future<void> clearToken() async {
    await _database.delete(AppKey.token);
    await _database.delete(AppKey.refreshToken);
    await _networkUtils.deleteToken();
  }

  @override
  Future<String?> readAccessToken() => _database.getString(AppKey.token);

  @override
  Future<String?> readRefreshToken() => _database.getString(AppKey.refreshToken);
}
