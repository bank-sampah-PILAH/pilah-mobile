// ignore_for_file: avoid_print
/// SPL Manager — Software Product Line CLI for Flutter Clean Architecture
///
/// Variability points:
///   Storage (OR)       — one or more backends, each registered with @Named
///   State Mgmt (OR)    — global default, per-feature override allowed
///
/// Usage:
///   dart run codegen/spl_manager.dart <command> [args]
///
/// Commands:
///   list
///   add <name> [name2 ...] [--with-storage] [--storage <provider>] [--with-test] [--shell-route] [--state bloc|cubit|riverpod]
///   disable <name> [name2 ...]           Move feature(s) to catalog (keeps code, unwires DI)
///   enable <name> [name2 ...]            Restore feature(s) from catalog (wires DI)
///   remove <name> [name2 ...] [--yes|-y] Hard delete
///   storage add <provider>
///   storage remove <provider>
///   storage default <provider>
///   storage list
///   state set <solution>       bloc|cubit|riverpod
///   state list
///   fix
library;

import 'dart:io';

part 'src/commands.dart';
part 'src/generators.dart';
part 'src/storage_manager.dart';
part 'src/templates.dart';
part 'src/spl_config.dart';
part 'src/utils.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

void main(List<String> args) async {
  if (args.isEmpty) {
    _printHelp();
    exit(0);
  }

  switch (args[0]) {
    case 'list':
      await _cmdList();

    case 'add':
      // Global defaults from flags
      final stateIdx = args.indexOf('--state');
      final globalState = stateIdx != -1 && stateIdx + 1 < args.length
          ? args[stateIdx + 1]
          : null;
      final storageIdx = args.indexOf('--storage');
      final globalStorageOverride =
          storageIdx != -1 && storageIdx + 1 < args.length
              ? args[storageIdx + 1]
              : null;
      final globalWithStorage =
          args.contains('--with-storage') || globalStorageOverride != null;
      final globalWithTest = args.contains('--with-test');
      final globalShellRoute = args.contains('--shell-route');
      // Collect feature specs — positional args (may include inline ,options)
      final specs = <String>[];
      for (var i = 1; i < args.length; i++) {
        if (args[i].startsWith('-')) continue;
        if (stateIdx != -1 && i == stateIdx + 1) continue;
        if (storageIdx != -1 && i == storageIdx + 1) continue;
        specs.add(args[i]);
      }
      if (specs.isEmpty)
        _die(
          'Usage: add <name>[,storage=<p>][,state=<s>][,test][,shell] [name2[,...]] ...\n'
          '  Global flags (apply to all unless overridden inline):\n'
          '    --with-storage  --storage <provider>  --with-test  --shell-route  --state <s>',
        );
      for (final spec in specs) {
        final f = _parseFeatureSpec(spec,
            globalStorageOverride: globalStorageOverride,
            globalWithStorage: globalWithStorage,
            globalState: globalState,
            globalWithTest: globalWithTest,
            globalShellRoute: globalShellRoute);
        await _cmdAdd(f.name,
            withStorage: f.withStorage,
            storageOverride: f.storageOverride,
            withTest: f.withTest,
            shellRoute: f.shellRoute,
            stateOverride: f.stateOverride,
            runDi: false);
      }
      print('\n  Wiring DI (build_runner)...');
      await _runBuildRunner();
      if (specs.length == 1) {
        final module = specs[0]
            .split(',')[0]
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        print('\n  ✓ Done! lib/features/$module/');
      } else {
        print('\n  ✓ Done! ${specs.length} features added.');
      }

    case 'disable':
      final names = args.skip(1).where((a) => !a.startsWith('-')).toList();
      if (names.isEmpty) _die('Usage: disable <name> [name2 ...]');
      for (final name in names) await _cmdDisable(name, runDi: false);
      print('  Regenerating DI...');
      await _runBuildRunner();
      if (names.length > 1) print('\n  ✓ ${names.length} features disabled.');

    case 'enable':
      final names = args.skip(1).where((a) => !a.startsWith('-')).toList();
      if (names.isEmpty) _die('Usage: enable <name> [name2 ...]');
      for (final name in names) await _cmdEnable(name, runDi: false);
      print('  Wiring DI (build_runner)...');
      await _runBuildRunner();
      if (names.length > 1) print('\n  ✓ ${names.length} features enabled.');

    case 'remove':
      final names = args.skip(1).where((a) => !a.startsWith('-')).toList();
      if (names.isEmpty) _die('Usage: remove <name> [name2 ...] [--yes|-y]');
      final force = args.contains('--yes') || args.contains('-y');
      var needsDi = false;
      for (final name in names) {
        if (await _cmdRemove(name, force: force, runDi: false)) needsDi = true;
      }
      if (needsDi) {
        print('  Regenerating DI...');
        await _runBuildRunner();
      }
      if (names.length > 1) print('\n  ✓ ${names.length} features removed.');

    case 'storage':
      if (args.length < 2)
        _die('Usage: storage add|remove|default|list [<provider>]');
      switch (args[1]) {
        case 'add':
          if (args.length < 3) _die('Usage: storage add <provider>');
          await _cmdStorageAdd(args[2]);
        case 'remove':
          if (args.length < 3) _die('Usage: storage remove <provider>');
          await _cmdStorageRemove(args[2]);
        case 'default':
          if (args.length < 3) _die('Usage: storage default <provider>');
          _cmdStorageDefault(args[2]);
        case 'list':
          _cmdStorageList();
        default:
          _die(
              'Unknown storage subcommand: ${args[1]}\nValid: add | remove | default | list');
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
