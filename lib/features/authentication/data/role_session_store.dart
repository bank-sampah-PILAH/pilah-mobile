import 'dart:convert';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';

class RoleSessionStore {
  const RoleSessionStore(this.database, this.network);
  final SecureDatabase database;
  final NetworkUtils network;
  static const key = 'role_session';

  Future<void> save(String access, String refresh) async {
    // One keystore entry prevents an access token from being paired with the
    // previous role's refresh token if a second write fails.
    await database.write(key: key, value: jsonEncode({
      'access_token': access, 'refresh_token': refresh,
    }));
    await network.setToken(accessToken: access, refreshToken: refresh);
  }
}
