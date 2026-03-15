// ignore_for_file: avoid_print
part of '../spl_manager.dart';

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
