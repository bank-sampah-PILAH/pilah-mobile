import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/core/storage/impl/secure_storage_provider.dart';
import 'package:pilah_mobile/core/storage/impl/shared_prefs_storage_provider.dart';
import 'package:pilah_mobile/core/storage/storage_module.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsStorageProvider', () {
    late SharedPrefsStorageProvider storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = SharedPrefsStorageProvider();
      await storage.init();
    });

    test('keeps each supported type under its own key', () async {
      await storage.put('int', 3);
      await storage.put('double', 1.5);
      await storage.put('bool', true);
      await storage.put('text', 'halo');
      await storage.put('other', 42.toString().length);

      expect(await storage.get<int>('int'), 3);
      expect(await storage.get<double>('double'), 1.5);
      expect(await storage.get<bool>('bool'), isTrue);
      expect(await storage.get<String>('text'), 'halo');
    });

    test('anything else is stored as its string form', () async {
      await storage.put('list', [1, 2]);

      expect(await storage.get<String>('list'), '[1, 2]');
    });

    test('a missing key reads as null', () async {
      expect(await storage.get<String>('nope'), isNull);
      expect(await storage.contains('nope'), isFalse);
    });

    test('delete and clear remove values', () async {
      await storage.put('a', 'x');
      await storage.put('b', 'y');

      await storage.delete('a');
      expect(await storage.contains('a'), isFalse);
      expect(await storage.contains('b'), isTrue);

      await storage.clear();
      expect(await storage.contains('b'), isFalse);
    });
  });

  group('SecureStorageProvider', () {
    late SecureStorageProvider storage;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      storage = const SecureStorageProvider(FlutterSecureStorage());
      await storage.init();
    });

    test('stores values as text and parses them back by requested type',
        () async {
      await storage.put('int', 7);
      await storage.put('double', 2.5);
      await storage.put('bool', true);
      await storage.put('text', 'halo');

      expect(await storage.get<int>('int'), 7);
      expect(await storage.get<double>('double'), 2.5);
      expect(await storage.get<bool>('bool'), isTrue);
      expect(await storage.get<String>('text'), 'halo');
    });

    test('an unparsable number reads as null', () async {
      await storage.put('text', 'bukan angka');

      expect(await storage.get<int>('text'), isNull);
      expect(await storage.get<double>('text'), isNull);
    });

    test('a missing key reads as null', () async {
      expect(await storage.get<String>('nope'), isNull);
      expect(await storage.contains('nope'), isFalse);
    });

    test('delete and clear remove values', () async {
      await storage.put('a', 'x');
      await storage.put('b', 'y');

      await storage.delete('a');
      expect(await storage.contains('a'), isFalse);

      await storage.clear();
      expect(await storage.contains('b'), isFalse);
    });
  });

  group('SecureDatabaseImpl', () {
    test('writes, reads and deletes through secure storage', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const db = SecureDatabaseImpl();

      await db.write(key: 'token', value: 'abc');
      expect(await db.getString('token'), 'abc');

      await db.delete('token');
      expect(await db.getString('token'), isNull);
    });
  });

  test('the storage module offers both providers', () {
    final module = _Module();

    expect(module.flutterSecureStorage, isA<SecureStorageProvider>());
    expect(module.sharedPreferences, isA<SharedPrefsStorageProvider>());
  });
}

class _Module extends StorageModule {}
