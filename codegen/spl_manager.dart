// ignore_for_file: avoid_print
/// SPL Manager — Software Product Line CLI for Flutter Clean Architecture
///
/// Variability points:
///   Storage (XOR)      — one backend for the whole app
///   State Mgmt (OR)    — global default, per-feature override allowed
///
/// Usage:
///   dart run codegen/spl_manager.dart <command> [args]
///
/// Commands:
///   list
///   add <name> [--with-storage] [--with-test] [--shell-route] [--state bloc|cubit|riverpod]
///   disable <name>             Move feature to catalog (keeps code, unwires DI)
///   enable <name>              Restore feature from catalog (wires DI)
///   remove <name> [--yes|-y]   Hard delete (works on active or catalog features)
///   storage set <provider>     flutter_secure_storage|sqflite|hive|shared_preferences
///   storage list
///   state set <solution>       bloc|cubit|riverpod
///   state list
///   fix
library;

import 'dart:io';

// ─── Entry point ──────────────────────────────────────────────────────────────

void main(List<String> args) async {
  if (args.isEmpty) { _printHelp(); exit(0); }

  switch (args[0]) {
    case 'list':
      await _cmdList();
    case 'add':
      if (args.length < 2) _die('Usage: add <name> [--with-storage] [--with-test] [--shell-route] [--state bloc|cubit|riverpod]');
      final withStorage   = args.contains('--with-storage');
      final withTest      = args.contains('--with-test');
      final shellRoute    = args.contains('--shell-route');
      final stateIdx      = args.indexOf('--state');
      final stateOverride = stateIdx != -1 && stateIdx + 1 < args.length
          ? args[stateIdx + 1]
          : null;
      await _cmdAdd(args[1],
          withStorage: withStorage,
          withTest: withTest,
          shellRoute: shellRoute,
          stateOverride: stateOverride);
    case 'disable':
      if (args.length < 2) _die('Usage: disable <name>');
      await _cmdDisable(args[1]);
    case 'enable':
      if (args.length < 2) _die('Usage: enable <name>');
      await _cmdEnable(args[1]);
    case 'remove':
      if (args.length < 2) _die('Usage: remove <name> [--yes|-y]');
      final force = args.contains('--yes') || args.contains('-y');
      await _cmdRemove(args[1], force: force);
    case 'storage':
      if (args.length < 2) _die('Usage: storage set <provider> | storage list');
      if (args[1] == 'set') {
        if (args.length < 3) _die('Usage: storage set <provider>');
        await _cmdStorageSet(args[2]);
      } else if (args[1] == 'list') {
        _cmdStorageList();
      } else {
        _die('Unknown storage subcommand: ${args[1]}');
      }
    case 'state':
      if (args.length < 2) _die('Usage: state set <solution> | state list');
      if (args[1] == 'set') {
        if (args.length < 3) _die('Usage: state set <bloc|cubit|riverpod>');
        _cmdStateSet(args[2]);
      } else if (args[1] == 'list') {
        _cmdStateList();
      } else {
        _die('Unknown state subcommand: ${args[1]}');
      }
    case 'fix':
      await _cmdFix();
    default:
      _die('Unknown command: ${args[0]}');
  }
}

// ─── Commands ─────────────────────────────────────────────────────────────────

Future<void> _cmdList() async {
  final config = _readSplConfig();
  _printHeader('SPL Configuration');

  final storage = config['storage']?['local_backend'] ?? 'flutter_secure_storage';
  final stateDefault = config['state_management']?['default'] ?? 'bloc';

  print('  App              : ${config['app']?['name'] ?? 'unknown'}');
  print('  Storage [XOR]    : $storage');
  print('  State Mgmt [OR]  : $stateDefault (default, per-feature override allowed)');
  print('');

  final features = config['features'] as List<Map<String, String>>? ?? [];
  if (features.isEmpty) {
    print('  No features yet.');
    print('    dart run codegen/spl_manager.dart add <name>');
    return;
  }

  final active   = features.where((f) => (f['status'] ?? 'active') == 'active').toList();
  final inactive = features.where((f) => (f['status'] ?? 'active') == 'inactive').toList();

  print('  Active features  [compiled + DI-wired]:');
  if (active.isEmpty) {
    print('    (none)');
  } else {
    for (final f in active) {
      final name       = f['name'] ?? '?';
      final storage    = f['storage'] ?? 'none';
      final state      = f['state'] ?? stateDefault;
      final desc       = f['description'] ?? '';
      final storageTag = storage == 'none' ? '' : '  storage:$storage';
      print('  ✓  $name  state:$state$storageTag');
      if (desc.isNotEmpty && desc != '""') print('      $desc');
    }
  }

  if (inactive.isNotEmpty) {
    print('');
    print('  Catalog  [code preserved, not compiled]:');
    for (final f in inactive) {
      final name       = f['name'] ?? '?';
      final storage    = f['storage'] ?? 'none';
      final state      = f['state'] ?? stateDefault;
      final desc       = f['description'] ?? '';
      final storageTag = storage == 'none' ? '' : '  storage:$storage';
      print('  ○  $name  state:$state$storageTag');
      if (desc.isNotEmpty && desc != '""') print('      $desc');
    }
  }

  print('');
  print('  Tip: dart run codegen/spl_manager.dart storage list');
  print('       dart run codegen/spl_manager.dart state list');
}

Future<void> _cmdAdd(
  String name, {
  bool withStorage = false,
  bool withTest = false,
  bool shellRoute = false,
  String? stateOverride,
}) async {
  final module = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  final className = _toPascalCase(module);
  final featureDir = 'lib/features/$module';

  if (Directory(featureDir).existsSync()) {
    _die('Feature "$module" already exists at $featureDir');
  }
  if (Directory('features_catalog/$module').existsSync()) {
    _die('Feature "$module" exists in the catalog (disabled).\n'
        '  To restore it: dart run codegen/spl_manager.dart enable $module\n'
        '  To delete it:  dart run codegen/spl_manager.dart remove $module');
  }

  final config = _readSplConfig();
  final globalStorageBackend = config['storage']?['local_backend'] ?? 'flutter_secure_storage';
  final globalStateDefault = config['state_management']?['default'] ?? 'bloc';
  final stateChoice = stateOverride ?? globalStateDefault;

  _validateStateChoice(stateChoice);

  _printHeader('Adding feature: $module');
  print('  Class   : $className');
  print('  Storage : ${withStorage ? globalStorageBackend : 'none'}');
  print('  State   : $stateChoice${stateOverride != null ? ' (override)' : ' (default)'}');
  print('  Route   : ${shellRoute ? 'shell (bottom nav)' : 'top-level'}');
  print('  Tests   : ${withTest ? 'yes (--with-test)' : 'no'}');
  print('  DI      : auto-wired via build_runner (@injectable)');
  print('');

  final usedMason = await _tryMasonFeature(module,
      withStorage: withStorage, state: stateChoice);
  if (!usedMason) {
    _generateFeatureFiles(module, className,
        withStorage: withStorage, state: stateChoice);
  }

  _addFeatureToConfig(
    module,
    storage: withStorage ? globalStorageBackend : 'none',
    state: stateChoice,
  );

  _injectRoute(module, className, shellRoute: shellRoute);

  if (withTest) _generateTestFiles(module, className, state: stateChoice);

  _printStateNotes(stateChoice);

  print('\n  Wiring DI (build_runner)...');
  await _runBuildRunner();

  print('\n  ✓ Done! lib/features/$module/');
}

Future<void> _cmdDisable(String name) async {
  final module = name.toLowerCase();
  final activeDir   = 'lib/features/$module';
  final catalogDir  = 'features_catalog/$module';

  _printHeader('Disabling feature: $module');

  if (!Directory(activeDir).existsSync()) {
    if (Directory(catalogDir).existsSync()) {
      _die('Feature "$module" is already disabled (in catalog).');
    }
    _die('Feature "$module" not found.');
  }

  Directory('features_catalog').createSync();
  Directory(activeDir).renameSync(catalogDir);
  print('  ○  Moved: $activeDir  →  $catalogDir');

  _removeRoute(module);
  _updateFeatureStatusInConfig(module, 'inactive');

  print('  Regenerating DI...');
  await _runBuildRunner();
  print('\n  ✓ Feature "$module" disabled.');
  print('  → Restore with: dart run codegen/spl_manager.dart enable $module');
}

Future<void> _cmdEnable(String name) async {
  final module = name.toLowerCase();
  final activeDir   = 'lib/features/$module';
  final catalogDir  = 'features_catalog/$module';

  _printHeader('Enabling feature: $module');

  if (!Directory(catalogDir).existsSync()) {
    if (Directory(activeDir).existsSync()) {
      _die('Feature "$module" is already active.');
    }
    _die('Feature "$module" not found in catalog.\n'
        '  Add it fresh: dart run codegen/spl_manager.dart add $module');
  }

  Directory('lib/features').createSync(recursive: true);
  Directory(catalogDir).renameSync(activeDir);
  print('  ✓  Moved: $catalogDir  →  $activeDir');

  _updateFeatureStatusInConfig(module, 'active');

  print('  Wiring DI (build_runner)...');
  await _runBuildRunner();
  print('\n  ✓ Feature "$module" enabled.');
  print('  → Ensure route is registered in lib/core/router/app_router_config.dart');
}

Future<void> _cmdRemove(String name, {bool force = false}) async {
  final module = name.toLowerCase();
  final activeDir  = 'lib/features/$module';
  final catalogDir = 'features_catalog/$module';

  final inActive  = Directory(activeDir).existsSync();
  final inCatalog = Directory(catalogDir).existsSync();

  if (!inActive && !inCatalog) _die('Feature "$module" not found.');

  final location = inActive ? activeDir : catalogDir;
  _printHeader('Removing feature: $module');
  print('  Location: $location${inCatalog ? ' (disabled)' : ' (active)'}');

  if (!force) {
    stdout.write('  Permanently delete "$module"? [y/N] ');
    final confirm = stdin.readLineSync()?.toLowerCase();
    if (confirm != 'y' && confirm != 'yes') { print('  Aborted.'); exit(0); }
  }

  Directory(location).deleteSync(recursive: true);
  print('  Deleted: $location');
  _removeRoute(module);
  _removeTests(module);
  _removeFeatureFromConfig(module);

  if (inActive) {
    print('  Regenerating DI...');
    await _runBuildRunner();
  }
  print('\n  ✓ Feature "$module" permanently removed.');
}

Future<void> _cmdStorageSet(String provider) async {
  const valid = ['flutter_secure_storage', 'sqflite', 'hive', 'shared_preferences'];
  if (!valid.contains(provider)) {
    _die('Unknown provider: "$provider"\nValid: ${valid.join(' | ')}');
  }

  final current = _getActiveProviderName();
  if (current == provider) { print('\n  Already using "$provider".'); exit(0); }

  _printHeader('Switching storage [XOR]: $current → $provider');

  _deleteStorageImpl(current);

  final usedMason = await _tryMasonStorage(provider);
  if (!usedMason) _generateStorageImpl(provider);

  _rewriteStorageModule(provider);
  _updateStorageInConfig(provider);

  print('\n  Regenerating DI...');
  await _runBuildRunner();

  print('\n  ✓ Storage → "$provider"');
  _printStorageNotes(provider);
}

void _cmdStorageList() {
  _printHeader('Storage Providers  [XOR — exactly one active]');
  final current = _getActiveProviderName();
  final providers = {
    'flutter_secure_storage': 'Encrypted key-value. Strings only. Best for sensitive data.',
    'sqflite':                'SQLite (relational). Best for structured/queryable data.',
    'hive':                   'NoSQL box store. Fast reads. Best for object graphs.',
    'shared_preferences':     'Simple key-value. Non-encrypted. Best for user settings.',
  };
  for (final e in providers.entries) {
    final active = e.key == current ? '  ◀ active' : '';
    print('  ${e.key}$active');
    print('      ${e.value}');
    print('');
  }
  print('  Switch (XOR): dart run codegen/spl_manager.dart storage set <provider>');
}

void _cmdStateSet(String solution) {
  _validateStateChoice(solution);
  _updateStateDefaultInConfig(solution);
  _printHeader('State Management Default → $solution');
  print('  Updated spl.yaml default.');
  print('  Existing features are unchanged.');
  print('  New features will use: $solution');
  _printStateNotes(solution);
}

void _cmdStateList() {
  _printHeader('State Management  [OR — global default + per-feature override]');
  final config = _readSplConfig();
  final current = config['state_management']?['default'] ?? 'bloc';

  final solutions = {
    'bloc': [
      'flutter_bloc (already in pubspec)',
      'Event + State + Bloc. Explicit event stream. Best for complex flows.',
      'Files: <name>_event.dart  <name>_state.dart  <name>_bloc.dart',
    ],
    'cubit': [
      'flutter_bloc (already in pubspec, same package as bloc)',
      'State + Cubit only. No event classes. Simpler, fewer files.',
      'Files: <name>_state.dart  <name>_cubit.dart',
    ],
    'riverpod': [
      'flutter_riverpod (add to pubspec if not present)',
      'Notifier + Provider. Different DI model. Bridges to get_it via di<T>().',
      'Files: <name>_state.dart  <name>_notifier.dart',
    ],
  };

  for (final e in solutions.entries) {
    final active = e.key == current ? '  ◀ default' : '';
    print('  ${e.key}$active');
    for (final line in e.value) print('      $line');
    print('');
  }

  print('  Change default : dart run codegen/spl_manager.dart state set <solution>');
  print('  Per-feature    : dart run codegen/spl_manager.dart add <name> --state <solution>');
  print('');
  print('  Note: bloc and cubit coexist freely (same package).');
  print('        riverpod requires flutter_riverpod in pubspec.yaml.');
}

Future<void> _cmdFix() async {
  _printHeader('Running build_runner');
  await _runBuildRunner();
  print('  ✓ Done');
}

// ─── Feature file generation ──────────────────────────────────────────────────

void _generateFeatureFiles(
  String module,
  String className, {
  bool withStorage = false,
  String state = 'bloc',
}) {
  final dirs = [
    'lib/features/$module/data/local',
    'lib/features/$module/data/model/mapper',
    'lib/features/$module/data/model/responses',
    'lib/features/$module/data/remote',
    'lib/features/$module/domain/model',
    'lib/features/$module/domain/repository',
    'lib/features/$module/domain/use_cases',
    if (state == 'riverpod')
      'lib/features/$module/presentation/providers'
    else
      'lib/features/$module/presentation/blocs',
    'lib/features/$module/presentation/pages',
    'lib/features/$module/presentation/widgets',
  ];
  for (final d in dirs) Directory(d).createSync(recursive: true);

  final files = <String, String>{
    // Data layer
    'lib/features/$module/data/local/${module}_local_data_sources.dart':
        _tplLocalDataSources(module, className, withStorage: withStorage),
    'lib/features/$module/data/model/mapper/${module}_mapper.dart':
        _tplMapper(module, className),
    'lib/features/$module/data/model/responses/${module}_response.dart':
        _tplResponse(module, className),
    'lib/features/$module/data/remote/${module}_remote_data_sources.dart':
        _tplRemoteDataSources(module, className),
    'lib/features/$module/data/${module}_repository_impl.dart':
        _tplRepositoryImpl(module, className),
    // Domain layer
    'lib/features/$module/domain/model/$module.dart': _tplModel(className),
    'lib/features/$module/domain/repository/${module}_repository.dart':
        _tplRepository(module, className),
    'lib/features/$module/domain/use_cases/${module}_use_cases.dart':
        _tplUseCases(module, className),
    'lib/features/$module/domain/${module}_interactor.dart':
        _tplInteractor(module, className),
    // Presentation — page (always the same)
    'lib/features/$module/presentation/pages/${module}_page.dart':
        _tplPage(module, className),
  };

  // Presentation — state management varies
  files.addAll(_stateFiles(module, className, state));

  for (final e in files.entries) {
    File(e.key).writeAsStringSync(e.value);
    print('  +  ${e.key}');
  }
}

Map<String, String> _stateFiles(String module, String className, String state) {
  switch (state) {
    case 'cubit':
      return {
        'lib/features/$module/presentation/blocs/${module}_state.dart':
            _tplState(className),
        'lib/features/$module/presentation/blocs/${module}_cubit.dart':
            _tplCubit(module, className),
      };
    case 'riverpod':
      return {
        'lib/features/$module/presentation/providers/${module}_state.dart':
            _tplState(className),
        'lib/features/$module/presentation/providers/${module}_notifier.dart':
            _tplRiverpodNotifier(module, className),
      };
    default: // bloc
      return {
        'lib/features/$module/presentation/blocs/${module}_event.dart':
            _tplEvent(className),
        'lib/features/$module/presentation/blocs/${module}_state.dart':
            _tplState(className),
        'lib/features/$module/presentation/blocs/${module}_bloc.dart':
            _tplBloc(module, className),
      };
  }
}

// ─── Route injection ──────────────────────────────────────────────────────────

void _injectRoute(String module, String className, {bool shellRoute = false}) {
  const routerPath = 'lib/core/router/app_router_config.dart';
  if (!File(routerPath).existsSync()) {
    print('  ⚠  Router not found at $routerPath — skipping route injection.');
    print('     Register the route manually.');
    return;
  }

  var content = File(routerPath).readAsStringSync();
  final pageImport =
      "import 'package:boilerplate/features/$module/presentation/pages/${module}_page.dart';";

  if (content.contains('${className}Page.route')) {
    print('  ~  Route for $className already exists — skipping.');
    return;
  }

  // Add import — insert before 'import package:flutter'
  content = content.replaceFirst(
    "import 'package:flutter/",
    "$pageImport\nimport 'package:flutter/",
  );

  if (shellRoute) {
    // Find the last GoRoute inside ShellRoute and append after it
    const anchor = "builder: (context, state) => const ProfilePage())";
    final newEntry = "\n          GoRoute(\n"
        "              path: ${className}Page.route,\n"
        "              name: ${className}Page.route,\n"
        "              parentNavigatorKey: _shellKey,\n"
        "              pageBuilder: (context, state) =>\n"
        "                  const NoTransitionPage(child: ${className}Page()),\n"
        "              builder: (context, state) => const ${className}Page())";
    content = content.replaceFirst(anchor, '$anchor$newEntry');
  } else {
    // Insert top-level GoRoute before ShellRoute(
    const anchor = '      ShellRoute(';
    final newEntry = "      GoRoute(\n"
        "          path: ${className}Page.route,\n"
        "          name: ${className}Page.route,\n"
        "          builder: (context, state) => const ${className}Page()),\n";
    content = content.replaceFirst(anchor, '$newEntry      ShellRoute(');
  }

  File(routerPath).writeAsStringSync(content);
  print('  ~  lib/core/router/app_router_config.dart  (route injected)');
}

void _removeRoute(String module) {
  const routerPath = 'lib/core/router/app_router_config.dart';
  if (!File(routerPath).existsSync()) return;

  final className = _toPascalCase(module);
  var content = File(routerPath).readAsStringSync();
  final before = content.length;

  // Remove the import line
  content = content.replaceAll(
    "import 'package:boilerplate/features/$module/presentation/pages/${module}_page.dart';\n",
    '',
  );

  // Remove top-level GoRoute (exact format we generate)
  content = content.replaceAll(
    "      GoRoute(\n"
    "          path: ${className}Page.route,\n"
    "          name: ${className}Page.route,\n"
    "          builder: (context, state) => const ${className}Page()),\n",
    '',
  );

  // Remove shell GoRoute (exact format we generate)
  content = content.replaceAll(
    "\n          GoRoute(\n"
    "              path: ${className}Page.route,\n"
    "              name: ${className}Page.route,\n"
    "              parentNavigatorKey: _shellKey,\n"
    "              pageBuilder: (context, state) =>\n"
    "                  const NoTransitionPage(child: ${className}Page()),\n"
    "              builder: (context, state) => const ${className}Page())",
    '',
  );

  if (content.length != before) {
    File(routerPath).writeAsStringSync(content);
    print('  ~  lib/core/router/app_router_config.dart  (route removed)');
  }
}

void _removeTests(String module) {
  final testDir = Directory('test/features/$module');
  if (testDir.existsSync()) {
    testDir.deleteSync(recursive: true);
    print('  Deleted: test/features/$module');
  }
}

// ─── Test file generation ─────────────────────────────────────────────────────

void _generateTestFiles(String module, String className, {String state = 'bloc'}) {
  final testDir = 'test/features/$module';
  Directory('$testDir/domain').createSync(recursive: true);
  Directory('$testDir/presentation').createSync(recursive: true);

  final files = <String, String>{
    '$testDir/domain/${module}_interactor_test.dart':
        _tplInteractorTest(module, className),
  };

  switch (state) {
    case 'cubit':
      files['$testDir/presentation/${module}_cubit_test.dart'] =
          _tplCubitTest(module, className);
    case 'riverpod':
      files['$testDir/presentation/${module}_notifier_test.dart'] =
          _tplRiverpodTest(module, className);
    default: // bloc
      files['$testDir/presentation/${module}_bloc_test.dart'] =
          _tplBlocTest(module, className);
  }

  for (final e in files.entries) {
    File(e.key).writeAsStringSync(e.value);
    print('  +  ${e.key}');
  }
}

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

// ─── Code templates — State Management ───────────────────────────────────────

String _tplState(String className) => '''
import 'package:equatable/equatable.dart';

abstract class ${className}State extends Equatable {
  const ${className}State();
  @override
  List<Object?> get props => [];
}

class ${className}InitialState extends ${className}State {
  const ${className}InitialState();
}

class ${className}LoadingState extends ${className}State {
  const ${className}LoadingState();
}

class ${className}SuccessState extends ${className}State {
  final dynamic data;
  const ${className}SuccessState({required this.data});
  @override
  List<Object?> get props => [data];
}

class ${className}ErrorState extends ${className}State {
  final String message;
  const ${className}ErrorState({required this.message});
  @override
  List<Object?> get props => [message];
}
''';

// ── BLoC ──────────────────────────────────────────────────────────────────────

String _tplEvent(String className) => '''
import 'package:equatable/equatable.dart';

abstract class ${className}Event extends Equatable {
  const ${className}Event();
  @override
  List<Object?> get props => [];
}

class Get${className}Event extends ${className}Event {
  const Get${className}Event();
}
''';

String _tplBloc(String module, String className) => '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_cases/${module}_use_cases.dart';
import '${module}_event.dart';
import '${module}_state.dart';

@Injectable()
class ${className}Bloc extends Bloc<${className}Event, ${className}State> {
  final ${className}UseCases _useCases;

  ${className}Bloc(this._useCases) : super(const ${className}InitialState()) {
    on<Get${className}Event>(_onGet);
  }

  Future<void> _onGet(
    Get${className}Event event,
    Emitter<${className}State> emit,
  ) async {
    emit(const ${className}LoadingState());
    final result = await _useCases.getSomething();
    result.fold(
      (failure) => emit(${className}ErrorState(message: failure.message ?? '')),
      (data)    => emit(${className}SuccessState(data: data)),
    );
  }
}
''';

// ── Cubit ─────────────────────────────────────────────────────────────────────

String _tplCubit(String module, String className) => '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_cases/${module}_use_cases.dart';
import '${module}_state.dart';

// Cubit: no event classes needed. Call methods directly from UI.
// Uses flutter_bloc — same package as Bloc, no extra dependency.
@Injectable()
class ${className}Cubit extends Cubit<${className}State> {
  final ${className}UseCases _useCases;

  ${className}Cubit(this._useCases) : super(const ${className}InitialState());

  Future<void> getSomething() async {
    emit(const ${className}LoadingState());
    final result = await _useCases.getSomething();
    result.fold(
      (failure) => emit(${className}ErrorState(message: failure.message ?? '')),
      (data)    => emit(${className}SuccessState(data: data)),
    );
  }
}
''';

// ── Riverpod ──────────────────────────────────────────────────────────────────

String _tplRiverpodNotifier(String module, String className) => '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/di.dart';
import '../../domain/use_cases/${module}_use_cases.dart';
import '${module}_state.dart';

// Bridges injectable get_it DI → Riverpod.
// The domain/data layers stay injectable; only the presentation uses Riverpod.
final ${module}UseCasesProvider = Provider<${className}UseCases>(
  (ref) => di<${className}UseCases>(),
);

final ${module}NotifierProvider =
    AsyncNotifierProvider.autoDispose<${className}Notifier, ${className}State>(
  ${className}Notifier.new,
);

class ${className}Notifier
    extends AutoDisposeAsyncNotifier<${className}State> {
  late ${className}UseCases _useCases;

  @override
  Future<${className}State> build() async {
    _useCases = ref.read(${module}UseCasesProvider);
    return const ${className}InitialState();
  }

  Future<void> getSomething() async {
    state = const AsyncValue.loading();
    final result = await _useCases.getSomething();
    result.fold(
      (failure) => state =
          AsyncError(failure.message ?? 'Error', StackTrace.current),
      (data) => state = AsyncData(${className}SuccessState(data: data)),
    );
  }
}
''';

// ─── Storage provider templates ───────────────────────────────────────────────

String _tplSecureStorageProvider() => r'''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app_storage.dart';

/// [AppStorage] backed by FlutterSecureStorage.
/// Managed by spl_manager. To switch: dart run codegen/spl_manager.dart storage set <provider>
class SecureStorageProvider implements AppStorage {
  final FlutterSecureStorage _storage;
  const SecureStorageProvider(this._storage);

  @override Future<void> init() async {}

  @override
  Future<void> put(String key, dynamic value) async =>
      _storage.write(key: key, value: value.toString());

  @override
  Future<T?> get<T>(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == bool) return (value == 'true') as T?;
    return value as T?;
  }

  @override Future<void> delete(String key) async => _storage.delete(key: key);
  @override Future<void> clear() async => _storage.deleteAll();
  @override Future<bool> contains(String key) async =>
      _storage.containsKey(key: key);
}
''';

String _tplSqfliteProvider() => r'''
import 'package:sqflite/sqflite.dart';
import '../app_storage.dart';

/// [AppStorage] backed by sqflite.
/// Call di<AppStorage>().init() in main() before runApp().
class SqfliteStorageProvider implements AppStorage {
  Database? _db;
  static const _table = 'kv_store';

  @override
  Future<void> init() async {
    final path = await getDatabasesPath();
    _db = await openDatabase(
      '$path/app_storage.db',
      version: 1,
      onCreate: (db, _) async => db.execute(
        'CREATE TABLE $_table (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      ),
    );
  }

  @override
  Future<void> put(String key, dynamic value) async =>
      _db!.insert(_table, {'key': key, 'value': value.toString()},
          conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<T?> get<T>(String key) async {
    final rows = await _db!.query(_table, where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String;
    if (T == int) return int.tryParse(raw) as T?;
    if (T == double) return double.tryParse(raw) as T?;
    if (T == bool) return (raw == 'true') as T?;
    return raw as T?;
  }

  @override Future<void> delete(String key) async =>
      _db!.delete(_table, where: 'key = ?', whereArgs: [key]);
  @override Future<void> clear() async => _db!.delete(_table);
  @override Future<bool> contains(String key) async {
    final rows = await _db!.query(_table, where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty;
  }
}
''';

String _tplHiveProvider() => r'''
import 'package:hive_flutter/hive_flutter.dart';
import '../app_storage.dart';

/// [AppStorage] backed by Hive.
/// Requires: hive_flutter: ^1.1.0 in pubspec.yaml
/// Call di<AppStorage>().init() in main() before runApp().
class HiveStorageProvider implements AppStorage {
  late Box _box;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('app_storage');
  }

  @override Future<void> put(String key, dynamic value) async => _box.put(key, value);
  @override Future<T?> get<T>(String key) async => _box.get(key) as T?;
  @override Future<void> delete(String key) async => _box.delete(key);
  @override Future<void> clear() async => _box.clear();
  @override Future<bool> contains(String key) async => _box.containsKey(key);
}
''';

String _tplSharedPrefsProvider() => r'''
import 'package:shared_preferences/shared_preferences.dart';
import '../app_storage.dart';

/// [AppStorage] backed by SharedPreferences.
/// Requires: shared_preferences: ^2.3.0 in pubspec.yaml
/// Call di<AppStorage>().init() in main() before runApp().
class SharedPrefsStorageProvider implements AppStorage {
  late SharedPreferences _prefs;

  @override
  Future<void> init() async => _prefs = await SharedPreferences.getInstance();

  @override
  Future<void> put(String key, dynamic value) async {
    if (value is int)         await _prefs.setInt(key, value);
    else if (value is double)  await _prefs.setDouble(key, value);
    else if (value is bool)    await _prefs.setBool(key, value);
    else                       await _prefs.setString(key, value.toString());
  }

  @override Future<T?> get<T>(String key) async => _prefs.get(key) as T?;
  @override Future<void> delete(String key) async => _prefs.remove(key);
  @override Future<void> clear() async => _prefs.clear();
  @override Future<bool> contains(String key) async => _prefs.containsKey(key);
}
''';

// ─── Data/Domain templates (shared across all state mgmt choices) ─────────────

String _tplLocalDataSources(String module, String className,
    {bool withStorage = false}) {
  if (!withStorage) {
    return '''import 'package:injectable/injectable.dart';

abstract class ${className}LocalDataSources {}

@LazySingleton(as: ${className}LocalDataSources)
class ${className}LocalDataSourcesImpl implements ${className}LocalDataSources {
  const ${className}LocalDataSourcesImpl();
}
''';
  }
  return '''import 'package:boilerplate/core/storage/app_storage.dart';
import 'package:injectable/injectable.dart';

abstract class ${className}LocalDataSources {
  Future<void> cache(String key, dynamic value);
  Future<T?> getCached<T>(String key);
  Future<void> clearCache();
}

@LazySingleton(as: ${className}LocalDataSources)
class ${className}LocalDataSourcesImpl implements ${className}LocalDataSources {
  final AppStorage _storage;
  const ${className}LocalDataSourcesImpl(this._storage);

  @override
  Future<void> cache(String key, dynamic value) => _storage.put(key, value);

  @override
  Future<T?> getCached<T>(String key) => _storage.get<T>(key);

  @override
  Future<void> clearCache() => _storage.clear();
}
''';
}

String _tplMapper(String module, String className) => '''
import '../responses/${module}_response.dart';
import '../../../domain/model/$module.dart';

class ${className}Mapper {
  static $className mapResponseToDomain(${className}Response response) {
    return $className(id: response.id);
  }
}
''';

String _tplResponse(String module, String className) => '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${module}_response.freezed.dart';
part '${module}_response.g.dart';

@freezed
abstract class ${className}Response with _\$${className}Response {
  const factory ${className}Response({
    required int id,
  }) = _${className}Response;

  factory ${className}Response.fromJson(Map<String, dynamic> json) =>
      _\$${className}ResponseFromJson(json);
}
''';

String _tplRemoteDataSources(String module, String className) => '''
import 'package:boilerplate/core/client/network_service.dart';
import 'package:injectable/injectable.dart';

import '../model/responses/${module}_response.dart';

abstract class ${className}RemoteDataSources {
  Future<${className}Response> getSomething();
}

@LazySingleton(as: ${className}RemoteDataSources)
class ${className}RemoteDataSourceImpl implements ${className}RemoteDataSources {
  final NetworkService _networkService;
  const ${className}RemoteDataSourceImpl(this._networkService);

  @override
  Future<${className}Response> getSomething() async {
    // TODO: implement via _networkService
    throw UnimplementedError();
  }
}
''';

String _tplRepositoryImpl(String module, String className) => '''
import 'package:boilerplate/core/client/api_call.dart';
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'local/${module}_local_data_sources.dart';
import 'model/mapper/${module}_mapper.dart';
import 'remote/${module}_remote_data_sources.dart';
import '../domain/model/$module.dart';
import '../domain/repository/${module}_repository.dart';

@LazySingleton(as: ${className}Repository)
class ${className}RepositoryImpl implements ${className}Repository {
  final ${className}RemoteDataSources _remote;
  final ${className}LocalDataSources _local;

  const ${className}RepositoryImpl(this._remote, this._local);

  @override
  Future<Either<NetworkException, $className>> getSomething() {
    return apiCall<$className>(
      func: _remote.getSomething(),
      mapper: (value) => ${className}Mapper.mapResponseToDomain(value),
    );
  }
}
''';

String _tplModel(String className) => '''
class $className {
  final int id;
  const $className({required this.id});
}
''';

String _tplRepository(String module, String className) => '''
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import '../model/$module.dart';

abstract class ${className}Repository {
  Future<Either<NetworkException, $className>> getSomething();
}
''';

String _tplUseCases(String module, String className) => '''
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';

import '../model/$module.dart';

abstract class ${className}UseCases {
  Future<Either<NetworkException, $className>> getSomething();
}
''';

String _tplInteractor(String module, String className) => '''
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'model/$module.dart';
import 'repository/${module}_repository.dart';
import 'use_cases/${module}_use_cases.dart';

@LazySingleton(as: ${className}UseCases)
class ${className}Interactor implements ${className}UseCases {
  final ${className}Repository _repository;
  const ${className}Interactor(this._repository);

  @override
  Future<Either<NetworkException, $className>> getSomething() =>
      _repository.getSomething();
}
''';

String _tplPage(String module, String className) => '''
import 'package:flutter/material.dart';

class ${className}Page extends StatelessWidget {
  static const route = '/$module';
  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: const Center(child: Text('$className — replace me')),
    );
  }
}
''';

// ─── Test templates ───────────────────────────────────────────────────────────

String _tplInteractorTest(String module, String className) => '''
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:boilerplate/features/$module/domain/${module}_interactor.dart';
import 'package:boilerplate/features/$module/domain/model/$module.dart';
import 'package:boilerplate/features/$module/domain/repository/${module}_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class Mock${className}Repository extends Mock implements ${className}Repository {}

void main() {
  late ${className}Interactor interactor;
  late Mock${className}Repository mockRepository;

  setUp(() {
    mockRepository = Mock${className}Repository();
    interactor = ${className}Interactor(mockRepository);
  });

  group('${className}Interactor', () {
    test('getSomething returns data on success', () async {
      when(() => mockRepository.getSomething())
          .thenAnswer((_) async => Right($className(id: 1)));

      final result = await interactor.getSomething();

      expect(result.isRight(), true);
      verify(() => mockRepository.getSomething()).called(1);
    });

    test('getSomething returns failure on error', () async {
      when(() => mockRepository.getSomething())
          .thenAnswer((_) async => Left(NetworkException(message: 'error')));

      final result = await interactor.getSomething();

      expect(result.isLeft(), true);
    });
  });
}
''';

String _tplBlocTest(String module, String className) => '''
import 'package:bloc_test/bloc_test.dart';
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:boilerplate/features/$module/domain/model/$module.dart';
import 'package:boilerplate/features/$module/domain/use_cases/${module}_use_cases.dart';
import 'package:boilerplate/features/$module/presentation/blocs/${module}_bloc.dart';
import 'package:boilerplate/features/$module/presentation/blocs/${module}_event.dart';
import 'package:boilerplate/features/$module/presentation/blocs/${module}_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class Mock${className}UseCases extends Mock implements ${className}UseCases {}

void main() {
  late Mock${className}UseCases mockUseCases;

  setUp(() {
    mockUseCases = Mock${className}UseCases();
  });

  group('${className}Bloc', () {
    blocTest<${className}Bloc, ${className}State>(
      'emits [Loading, Success] when getSomething succeeds',
      build: () => ${className}Bloc(mockUseCases),
      setUp: () {
        when(() => mockUseCases.getSomething())
            .thenAnswer((_) async => Right($className(id: 1)));
      },
      act: (bloc) => bloc.add(const Get${className}Event()),
      expect: () => [
        const ${className}LoadingState(),
        isA<${className}SuccessState>(),
      ],
    );

    blocTest<${className}Bloc, ${className}State>(
      'emits [Loading, Error] when getSomething fails',
      build: () => ${className}Bloc(mockUseCases),
      setUp: () {
        when(() => mockUseCases.getSomething())
            .thenAnswer((_) async => Left(NetworkException(message: 'error')));
      },
      act: (bloc) => bloc.add(const Get${className}Event()),
      expect: () => [
        const ${className}LoadingState(),
        isA<${className}ErrorState>(),
      ],
    );
  });
}
''';

String _tplCubitTest(String module, String className) => '''
import 'package:bloc_test/bloc_test.dart';
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:boilerplate/features/$module/domain/model/$module.dart';
import 'package:boilerplate/features/$module/domain/use_cases/${module}_use_cases.dart';
import 'package:boilerplate/features/$module/presentation/blocs/${module}_cubit.dart';
import 'package:boilerplate/features/$module/presentation/blocs/${module}_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class Mock${className}UseCases extends Mock implements ${className}UseCases {}

void main() {
  late Mock${className}UseCases mockUseCases;

  setUp(() {
    mockUseCases = Mock${className}UseCases();
  });

  group('${className}Cubit', () {
    blocTest<${className}Cubit, ${className}State>(
      'emits [Loading, Success] when getSomething succeeds',
      build: () => ${className}Cubit(mockUseCases),
      setUp: () {
        when(() => mockUseCases.getSomething())
            .thenAnswer((_) async => Right($className(id: 1)));
      },
      act: (cubit) => cubit.getSomething(),
      expect: () => [
        const ${className}LoadingState(),
        isA<${className}SuccessState>(),
      ],
    );

    blocTest<${className}Cubit, ${className}State>(
      'emits [Loading, Error] when getSomething fails',
      build: () => ${className}Cubit(mockUseCases),
      setUp: () {
        when(() => mockUseCases.getSomething())
            .thenAnswer((_) async => Left(NetworkException(message: 'error')));
      },
      act: (cubit) => cubit.getSomething(),
      expect: () => [
        const ${className}LoadingState(),
        isA<${className}ErrorState>(),
      ],
    );
  });
}
''';

String _tplRiverpodTest(String module, String className) => '''
import 'package:boilerplate/core/client/network_exception.dart';
import 'package:boilerplate/features/$module/domain/model/$module.dart';
import 'package:boilerplate/features/$module/domain/use_cases/${module}_use_cases.dart';
import 'package:boilerplate/features/$module/presentation/providers/${module}_notifier.dart';
import 'package:boilerplate/features/$module/presentation/providers/${module}_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class Mock${className}UseCases extends Mock implements ${className}UseCases {}

void main() {
  late Mock${className}UseCases mockUseCases;

  setUp(() {
    mockUseCases = Mock${className}UseCases();
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          ${module}UseCasesProvider.overrideWithValue(mockUseCases),
        ],
      );

  group('${className}Notifier', () {
    test('initial state is ${className}InitialState', () async {
      when(() => mockUseCases.getSomething())
          .thenAnswer((_) async => Right($className(id: 1)));

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(${module}NotifierProvider.future);
      expect(state, isA<${className}InitialState>());
    });
  });
}
''';

// ─── spl.yaml helpers ─────────────────────────────────────────────────────────

Map<String, dynamic> _readSplConfig() {
  const path = 'spl.yaml';
  if (!File(path).existsSync()) _die('spl.yaml not found. Run from project root.');

  final lines = File(path).readAsLinesSync();
  final config = <String, dynamic>{};
  String? section;
  Map<String, String>? currentFeature;

  for (final line in lines) {
    if (line.trim().startsWith('#') || line.trim().isEmpty) continue;

    if (!line.startsWith(' ') && !line.startsWith('\t')) {
      section = line.trim().replaceAll(':', '');
      if (section == 'features') config['features'] = <Map<String, String>>[];
      continue;
    }

    final trimmed = line.trim();

    if (section == 'app' || section == 'storage' || section == 'state_management') {
      final idx = trimmed.indexOf(':');
      if (idx > 0) {
        config.putIfAbsent(section!, () => <String, String>{});
        (config[section] as Map<String, dynamic>)[trimmed.substring(0, idx).trim()] =
            trimmed.substring(idx + 1).trim();
      }
    }

    if (section == 'features') {
      if (trimmed.startsWith('- name:')) {
        currentFeature = {'name': trimmed.replaceFirst('- name:', '').trim()};
        (config['features'] as List).add(currentFeature);
      } else if (currentFeature != null) {
        final idx = trimmed.indexOf(':');
        if (idx > 0) {
          currentFeature[trimmed.substring(0, idx).trim()] =
              trimmed.substring(idx + 1).trim();
        }
      }
    }
  }

  return config;
}

void _addFeatureToConfig(String name,
    {required String storage, required String state}) {
  const path = 'spl.yaml';
  final content = File(path).readAsStringSync();
  File(path).writeAsStringSync(
    '$content\n  - name: $name\n    status: active\n    storage: $storage\n    state: $state\n',
  );
}

void _removeFeatureFromConfig(String name) {
  const path = 'spl.yaml';
  final lines = File(path).readAsLinesSync();
  final result = <String>[];
  bool skip = false;

  for (final line in lines) {
    if (line.trim() == '- name: $name') {
      skip = true;
      if (result.isNotEmpty && result.last.trim().isEmpty) result.removeLast();
      continue;
    }
    if (skip) {
      if (line.trim().startsWith('- name:') || !line.startsWith('  ')) {
        skip = false;
      } else {
        continue;
      }
    }
    result.add(line);
  }
  File(path).writeAsStringSync(result.join('\n'));
}

void _updateFeatureStatusInConfig(String name, String status) {
  const path = 'spl.yaml';
  final lines = File(path).readAsLinesSync();
  final result = <String>[];
  bool inFeature = false;
  bool patched = false;

  for (final line in lines) {
    if (line.trim() == '- name: $name') {
      inFeature = true;
      patched = false;
    } else if (inFeature && line.trim().startsWith('status:') && !patched) {
      result.add(line.replaceFirst(RegExp(r'status:\s*\w+'), 'status: $status'));
      patched = true;
      continue;
    } else if (inFeature && (line.trim().startsWith('- name:') || !line.startsWith('  '))) {
      inFeature = false;
    }
    result.add(line);
  }
  File(path).writeAsStringSync(result.join('\n'));
}

void _updateStorageInConfig(String provider) {
  const path = 'spl.yaml';
  File(path).writeAsStringSync(
    File(path).readAsStringSync().replaceFirst(
      RegExp(r'local_backend:.*'),
      'local_backend: $provider',
    ),
  );
}

void _updateStateDefaultInConfig(String solution) {
  const path = 'spl.yaml';
  File(path).writeAsStringSync(
    File(path).readAsStringSync().replaceFirst(
      RegExp(r'default: (bloc|cubit|riverpod)'),
      'default: $solution',
    ),
  );
}

// ─── Mason integration ────────────────────────────────────────────────────────

bool? _masonAvailable;

Future<bool> _checkMason() async {
  if (_masonAvailable != null) return _masonAvailable!;
  final r = await Process.run('mason', ['--version'], runInShell: true);
  _masonAvailable = r.exitCode == 0 && File('.mason/bricks.json').existsSync();
  return _masonAvailable!;
}

Future<bool> _tryMasonFeature(String module,
    {bool withStorage = false, String state = 'bloc'}) async {
  if (!await _checkMason()) return false;
  print('  Using Mason brick: feature');
  final r = await Process.run(
    'mason',
    ['make', 'feature',
      '--name', module,
      '--with_storage', withStorage.toString(),
      '--state', state,
      '-o', '.', '--no-confirm'],
    runInShell: true,
  );
  if (r.exitCode != 0) {
    print('  Mason failed → falling back to inline templates.');
    return false;
  }
  print(r.stdout);
  return true;
}

Future<bool> _tryMasonStorage(String provider) async {
  if (!await _checkMason()) return false;
  final brick = switch (provider) {
    'flutter_secure_storage' => 'storage_secure',
    'sqflite'                => 'storage_sqflite',
    'hive'                   => 'storage_hive',
    'shared_preferences'     => 'storage_prefs',
    _                        => null,
  };
  if (brick == null) return false;
  print('  Using Mason brick: $brick');
  final r = await Process.run(
    'mason', ['make', brick, '-o', '.', '--no-confirm'],
    runInShell: true,
  );
  if (r.exitCode != 0) {
    print('  Mason failed → falling back to inline templates.');
    return false;
  }
  print(r.stdout);
  return true;
}

// ─── Validation + Notes ───────────────────────────────────────────────────────

void _validateStateChoice(String state) {
  const valid = ['bloc', 'cubit', 'riverpod'];
  if (!valid.contains(state)) {
    _die('Unknown state: "$state"\nValid: ${valid.join(' | ')}');
  }
}

void _printStateNotes(String state) {
  if (state == 'riverpod') {
    print('');
    print('  ⚠  Riverpod requires: flutter_riverpod in pubspec.yaml');
    print('  ⚠  Add ProviderScope at the root of your widget tree in main()');
  }
}

void _printStorageNotes(String provider) {
  switch (provider) {
    case 'hive':
      print('\n  ⚠  Add: hive_flutter: ^1.1.0 to pubspec.yaml');
      print('  ⚠  Call di<AppStorage>().init() in main() before runApp()');
    case 'shared_preferences':
      print('\n  ⚠  Add: shared_preferences: ^2.3.0 to pubspec.yaml');
      print('  ⚠  Call di<AppStorage>().init() in main() before runApp()');
    case 'sqflite':
      print('\n  ⚠  Call di<AppStorage>().init() in main() before runApp()');
    default:
      break;
  }
}

// ─── build_runner ─────────────────────────────────────────────────────────────

Future<void> _runBuildRunner() async {
  final result = await Process.run(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    runInShell: true,
  );
  if (result.exitCode != 0) {
    print('\n${result.stderr}');
    _die('build_runner failed (exit ${result.exitCode})');
  }
  print('  build_runner: OK');
}

// ─── Utilities ────────────────────────────────────────────────────────────────

String _toPascalCase(String s) => s
    .split(RegExp(r'[_\s-]+'))
    .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
    .join();

void _printHeader(String t) {
  print('');
  print('  ══ $t ══');
  print('');
}

void _printHelp() {
  print('''
SPL Manager — Software Product Line CLI

Variability:
  Storage [XOR]     one backend for the whole app
  State Mgmt [OR]   global default + per-feature override

Commands:
  list
  add <name>                              Scaffold a new feature (active)
  add <name> --with-storage              Include local cache (AppStorage)
  add <name> --with-test                 Generate unit + state mgmt tests
  add <name> --shell-route               Register as shell (bottom nav) route
  add <name> --state bloc|cubit|riverpod Override state mgmt for this feature
  disable <name>                         Move to catalog — code kept, DI removed
  enable <name>                          Restore from catalog — DI re-wired
  remove <name> [--yes|-y]               Hard delete (active or catalog)
  storage set <provider>                 Switch storage (XOR)
  storage list
  state set <bloc|cubit|riverpod>        Change default state mgmt
  state list
  fix                                    Re-run build_runner
''');
}

Never _die(String msg) {
  stderr.writeln('\n  ✗  $msg\n');
  exit(1);
}
