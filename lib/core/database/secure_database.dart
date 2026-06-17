import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Abstraction for encrypted key-value storage.
/// Always backed by FlutterSecureStorage — this is NOT a variability point.
/// Use this for sensitive data only (tokens, auth keys).
///
/// For general feature local caching, inject [AppStorage] instead.
abstract class SecureDatabase {
  Future<void> write({required String key, required String value});
  Future<void> delete(String key);
  Future<String?> getString(String key);
}

@LazySingleton(as: SecureDatabase)
class SecureDatabaseImpl implements SecureDatabase {
  // FlutterSecureStorage is const — no need to inject it.
  static const _storage = FlutterSecureStorage();

  const SecureDatabaseImpl();

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }
}
