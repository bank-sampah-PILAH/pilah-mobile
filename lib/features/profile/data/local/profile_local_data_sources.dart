import 'package:boilerplate/core/constants/app_key.dart';
import 'package:boilerplate/core/database/secure_database.dart';
import 'package:injectable/injectable.dart';

abstract class ProfileLocalDataSources {
  Future<void> logOut();
}

@LazySingleton(as: ProfileLocalDataSources)
class ProfileLocalDataSourcesImpl implements ProfileLocalDataSources {
  final SecureDatabase _secureDatabase;

  ProfileLocalDataSourcesImpl(this._secureDatabase);

  @override
  Future<void> logOut() async {
    await _secureDatabase.delete(AppKey.token);
    await _secureDatabase.delete(AppKey.refreshToken);
  }
}
