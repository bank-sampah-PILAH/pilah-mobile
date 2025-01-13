import 'package:boilerplate/core/constants/app_key.dart';
import 'package:boilerplate/core/database/secure_database.dart';
import 'package:boilerplate/features/authentication/data/remote/model/request/save_token_request.dart';
import 'package:injectable/injectable.dart';

abstract class AuthLocalDataSources {
  Future<void> saveToken(SaveTokenRequest request);
}

@LazySingleton(as: AuthLocalDataSources)
class AuthLocalDataSourcesImpl implements AuthLocalDataSources {
  final SecureDatabase _database;

  const AuthLocalDataSourcesImpl(this._database);

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
  }
}
