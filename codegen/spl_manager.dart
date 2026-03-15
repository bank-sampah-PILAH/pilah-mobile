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

part 'src/commands.dart';
part 'src/generators.dart';
part 'src/storage_manager.dart';
part 'src/templates.dart';
part 'src/spl_config.dart';
part 'src/utils.dart';

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
