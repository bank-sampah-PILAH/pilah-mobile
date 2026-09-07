import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/save_token_request.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

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
    // In-memory first, and unconditionally. NetworkService.headersRequest reads
    // this to authenticate every request in the session, so it must be set the
    // moment login returns — before the app navigates on to onboarding and the
    // first authenticated call (POST profile) fires. Unlike the keystore-backed
    // writes below it cannot fail.
    await _networkUtils.setToken(
      accessToken: request.accessToken,
      refreshToken: request.refreshToken,
    );
    // Persisting to disk only matters for restoring the session on the next cold
    // start, so it is best-effort. A device whose keystore rejects the write —
    // a real, device-specific failure mode — must not turn a successful login
    // into a failure or leave the signed-in user unable to make authenticated
    // calls: they can finish onboarding now and re-authenticate next launch.
    try {
      await _database.write(key: AppKey.token, value: request.accessToken);
      await _database.write(
          key: AppKey.refreshToken, value: request.refreshToken);
    } catch (e) {
      Logger()
          .e('Secure storage write failed; session kept in memory only: $e');
    }
  }

  @override
  Future<void> clearToken() async {
    // In-memory first so the session is deauthenticated immediately, even if the
    // keystore delete below throws.
    await _networkUtils.deleteToken();
    try {
      await _database.delete(AppKey.token);
      await _database.delete(AppKey.refreshToken);
    } catch (e) {
      Logger().e('Secure storage delete failed: $e');
    }
  }

  @override
  Future<String?> readAccessToken() => _database.getString(AppKey.token);

  @override
  Future<String?> readRefreshToken() =>
      _database.getString(AppKey.refreshToken);
}
