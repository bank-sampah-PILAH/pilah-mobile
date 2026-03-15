// ignore_for_file: avoid_print
part of '../spl_manager.dart';

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
