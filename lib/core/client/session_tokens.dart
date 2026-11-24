import 'dart:convert';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';

class SessionTokens {
  const SessionTokens(this.access, this.refresh);
  final String? access;
  final String? refresh;
  static const key = 'role_session';

  static Future<SessionTokens> read(SecureDatabase database) async {
    final record = await database.getString(key);
    if (record != null) {
      final data = jsonDecode(record) as Map<String, dynamic>;
      return SessionTokens(
          data['access_token'] as String?, data['refresh_token'] as String?);
    }
    return SessionTokens(await database.getString(AppKey.token),
        await database.getString(AppKey.refreshToken));
  }
}
