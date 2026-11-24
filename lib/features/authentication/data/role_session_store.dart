import 'dart:convert';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/client/session_tokens.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';

class RoleSessionStore {
  const RoleSessionStore(this.database, this.network);
  final SecureDatabase database;
  final NetworkUtils network;
  static const key = SessionTokens.key;

  Future<void> save(String access, String refresh) async {
    final revision = network.sessionRevision;
    // One keystore entry prevents an access token from being paired with the
    // previous role's refresh token if a second write fails.
    final record = jsonEncode({
      'access_token': access, 'refresh_token': refresh,
    });
    await database.write(key: key, value: record);
    if (network.sessionRevision != revision) {
      if (await database.getString(key) == record) await database.delete(key);
      throw StateError('Session changed during secure storage write');
    }
    await network.setToken(accessToken: access, refreshToken: refresh);
  }
}
