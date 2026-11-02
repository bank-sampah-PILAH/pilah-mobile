import 'package:pilah_mobile/core/storage/app_storage.dart';

/// In-memory stand-in for the real key-value storage.
class FakeAppStorage implements AppStorage {
  final values = <String, dynamic>{};

  @override
  Future<void> init() async {}

  @override
  Future<void> put(String key, dynamic value) async => values[key] = value;

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}
