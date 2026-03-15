// ============================================================
// SPL MANAGED FILE — DO NOT EDIT MANUALLY
// Active providers: flutter_secure_storage
// Default: flutter_secure_storage
// To manage: dart run codegen/spl_manager.dart storage add|remove|default
// ============================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'impl/secure_storage_provider.dart';

import 'package:injectable/injectable.dart';
import 'app_storage.dart';

@module
abstract class StorageModule {
  @lazySingleton
  @Named('flutter_secure_storage')
  AppStorage get flutterSecureStorage => const SecureStorageProvider(FlutterSecureStorage());
}
