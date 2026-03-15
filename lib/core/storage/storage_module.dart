// ============================================================
// SPL MANAGED FILE — DO NOT EDIT MANUALLY
// Active provider: flutter_secure_storage
// To switch: dart run codegen/spl_manager.dart storage set <provider>
// Available: flutter_secure_storage | sqflite | hive | shared_preferences
// ============================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'impl/secure_storage_provider.dart';

import 'package:injectable/injectable.dart';
import 'app_storage.dart';

@module
abstract class StorageModule {
  @lazySingleton
  AppStorage get appStorage => const SecureStorageProvider(FlutterSecureStorage());
}
