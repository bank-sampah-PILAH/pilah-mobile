// ignore_for_file: avoid_print
part of '../spl_manager.dart';

// ─── Storage impl management ──────────────────────────────────────────────────

String _getActiveProviderName() {
  const path = 'lib/core/storage/storage_module.dart';
  if (!File(path).existsSync()) return 'flutter_secure_storage';
  final content = File(path).readAsStringSync();
  final match = RegExp(r'// Active provider: (\S+)').firstMatch(content);
  return match?.group(1)?.trim() ?? 'flutter_secure_storage';
}

String _implFileName(String provider) => switch (provider) {
  'flutter_secure_storage' => 'secure_storage_provider.dart',
  'sqflite'                => 'sqflite_storage_provider.dart',
  'hive'                   => 'hive_storage_provider.dart',
  'shared_preferences'     => 'shared_prefs_storage_provider.dart',
  _                        => _die('Unknown provider: $provider'),
};

String _implFilePath(String p) => 'lib/core/storage/impl/${_implFileName(p)}';

void _deleteStorageImpl(String provider) {
  final path = _implFilePath(provider);
  if (File(path).existsSync()) {
    File(path).deleteSync();
    print('  -  $path  (removed)');
  }
}

void _generateStorageImpl(String provider) {
  final path = _implFilePath(provider);
  File(path).writeAsStringSync(_storageImplContent(provider));
  print('  +  $path  (generated)');
}

String _storageImplContent(String provider) => switch (provider) {
  'flutter_secure_storage' => _tplSecureStorageProvider(),
  'sqflite'                => _tplSqfliteProvider(),
  'hive'                   => _tplHiveProvider(),
  'shared_preferences'     => _tplSharedPrefsProvider(),
  _                        => _die('Unknown provider: $provider'),
};

void _rewriteStorageModule(String provider) {
  final imports = switch (provider) {
    'flutter_secure_storage' =>
      "import 'package:flutter_secure_storage/flutter_secure_storage.dart';\nimport 'impl/secure_storage_provider.dart';",
    'sqflite'                => "import 'impl/sqflite_storage_provider.dart';",
    'hive'                   => "import 'impl/hive_storage_provider.dart';",
    'shared_preferences'     => "import 'impl/shared_prefs_storage_provider.dart';",
    _                        => _die('Unknown provider: $provider'),
  };
  final providerExpr = switch (provider) {
    'flutter_secure_storage' => 'const SecureStorageProvider(FlutterSecureStorage())',
    'sqflite'                => 'SqfliteStorageProvider()',
    'hive'                   => 'HiveStorageProvider()',
    'shared_preferences'     => 'SharedPrefsStorageProvider()',
    _                        => _die('Unknown provider: $provider'),
  };

  const path = 'lib/core/storage/storage_module.dart';
  File(path).writeAsStringSync('''// ============================================================
// SPL MANAGED FILE — DO NOT EDIT MANUALLY
// Active provider: $provider
// To switch: dart run codegen/spl_manager.dart storage set <provider>
// Available: flutter_secure_storage | sqflite | hive | shared_preferences
// ============================================================

$imports

import 'package:injectable/injectable.dart';
import 'app_storage.dart';

@module
abstract class StorageModule {
  @lazySingleton
  AppStorage get appStorage => $providerExpr;
}
''');
  print('  ~  lib/core/storage/storage_module.dart  (updated)');
}
