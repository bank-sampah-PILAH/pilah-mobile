import 'session_tokens.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class NetworkUtils {
  final SecureDatabase _secureDatabase;

  NetworkUtils(this._secureDatabase);

  String _accessToken = '';
  String _refreshToken = '';
  int _sessionRevision = 0;
  int get sessionRevision => _sessionRevision;

  String get accessToken => _accessToken;

  String get refreshToken => _refreshToken;

  Future<void> init() async {
    final tokens = await SessionTokens.read(_secureDatabase);
    _accessToken = tokens.access ?? '';
    _refreshToken = tokens.refresh ?? '';
  }

  Future<void> setToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    _sessionRevision++;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> deleteToken() async {
    _sessionRevision++;
    _accessToken = '';
    _refreshToken = '';
  }

  static String parseErrorMessage(dynamic value) {
    if (value is Map) {
      if (value['message'] != null) {
        return value['message'].toString();
      }
      return value.values.first.toString();
    }
    return value.toString();
  }
}
