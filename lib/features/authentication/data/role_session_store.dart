import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';

class RoleSessionStore {
  const RoleSessionStore(this.database, this.network);
  final SecureDatabase database;
  final NetworkUtils network;
  static const key = 'role_session';

  Future<void> save(String access, String refresh) async {
    await network.setToken(accessToken: access, refreshToken: refresh);
  }
}
