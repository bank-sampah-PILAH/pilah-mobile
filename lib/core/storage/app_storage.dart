/// Abstract interface for general-purpose local storage.
///
/// This is the SPL variability point for storage backends.
/// Use `dart run codegen/spl_manager.dart storage set <provider>` to switch.
/// Available: flutter_secure_storage | hive | sqflite | shared_preferences
abstract class AppStorage {
  /// Must be called once at app startup (e.g., in main()).
  Future<void> init();

  /// Store a value. Supported types depend on the active provider.
  /// All providers support: String, int, double, bool, List\<String>.
  Future<void> put(String key, dynamic value);

  /// Read a value. Returns null if the key doesn't exist.
  Future<T?> get<T>(String key);

  /// Delete a single key.
  Future<void> delete(String key);

  /// Delete all stored data.
  Future<void> clear();

  /// Returns true if the key exists.
  Future<bool> contains(String key);
}
