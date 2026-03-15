# Software Product Line (SPL) Guide

This project uses Software Product Line Engineering (SPLE) to manage variability points — features and behaviors that can differ between products derived from this template.

All variability is managed through a single CLI tool and a single config file.

The CLI source lives in `codegen/spl_manager.dart` and is split across `codegen/src/` using Dart's `part`/`part of` system — see [CLI Source Layout](#cli-source-layout).

---

## Quick Reference

```
dart run codegen/spl_manager.dart list
dart run codegen/spl_manager.dart add <spec> [spec2 ...]
dart run codegen/spl_manager.dart disable <name> [name2 ...]
dart run codegen/spl_manager.dart enable <name> [name2 ...]
dart run codegen/spl_manager.dart remove <name> [name2 ...] [--yes|-y]
dart run codegen/spl_manager.dart storage add <provider>
dart run codegen/spl_manager.dart storage remove <provider>
dart run codegen/spl_manager.dart storage default <provider>
dart run codegen/spl_manager.dart storage list
dart run codegen/spl_manager.dart state set <bloc|cubit|riverpod>
dart run codegen/spl_manager.dart state list
dart run codegen/spl_manager.dart fix
```

---

## Source of Truth: `spl.yaml`

`spl.yaml` is the single source of truth for the product configuration. It tracks the active storage backends, the default state management solution, and all features.

Do not edit `spl.yaml` by hand — use the CLI. The CLI updates this file, generates/deletes code, and re-wires DI automatically.

---

## Variability Points

This project has two variability points. Both use OR semantics.

### 1. Storage — OR (multiple backends can coexist)

Controls the backend(s) for `AppStorage`, the general-purpose local caching interface. Multiple providers can be active simultaneously — each feature declares which one it uses via `@Named`.

| Provider | Notes |
|---|---|
| `flutter_secure_storage` | Default. Encrypted key-value. No `init()` needed. |
| `hive` | Fast binary key-value. Requires `hive_flutter` in `pubspec.yaml` and `AppStorage.init()` before `runApp()`. |
| `sqflite` | SQLite (relational). Best for structured/queryable data. Requires `AppStorage.init()` before `runApp()`. |
| `shared_preferences` | Simple unencrypted key-value. Requires `shared_preferences` in `pubspec.yaml` and `AppStorage.init()` before `runApp()`. |

Each active provider is registered as `@Named('provider_name')` in `StorageModule`. Features inject the named variant they need.

```
dart run codegen/spl_manager.dart storage add sqflite
dart run codegen/spl_manager.dart storage remove hive
dart run codegen/spl_manager.dart storage default sqflite   # default for --with-storage
dart run codegen/spl_manager.dart storage list
```

When a feature is added with `--storage sqflite` (or `,storage=sqflite` inline), the CLI auto-registers `sqflite` if not already active, generates the impl file, and wires `@Named('sqflite')` into the feature's local data source.

### 2. State Management — OR (global default + per-feature override)

Controls the presentation layer pattern for features. Different features in the same app can use different solutions.

| Solution | Package | Files generated | Use when |
|---|---|---|---|
| `bloc` | `flutter_bloc` | `_event.dart`, `_state.dart`, `_bloc.dart` | Complex flows with explicit event streams |
| `cubit` | `flutter_bloc` (same package) | `_state.dart`, `_cubit.dart` | Simpler flows, fewer files, methods called directly |
| `riverpod` | `flutter_riverpod` | `_state.dart`, `_notifier.dart` | Riverpod-native UIs; bridges to get_it DI via `di<T>()` |

Change the global default (affects all future `add` commands):
```
dart run codegen/spl_manager.dart state set cubit
```

Override per feature at creation time:
```
dart run codegen/spl_manager.dart add orders --state riverpod
dart run codegen/spl_manager.dart add orders,state=riverpod     # inline equivalent
```

Bloc and cubit coexist with zero config (same `flutter_bloc` package). Riverpod requires:
1. `flutter_riverpod` in `pubspec.yaml`
2. `ProviderScope` wrapping your root widget in `main.dart`

---

## Storage Architecture: Two Separate Concerns

There are two storage abstractions in this project. They solve different problems and are **not interchangeable**.

### `SecureDatabase` — encrypted token store (NOT a variability point)

```
lib/core/database/secure_database.dart
```

Always backed by `FlutterSecureStorage`. **This is intentional and not configurable.**

`FlutterSecureStorage` writes to the OS keychain (iOS Keychain / Android Keystore), providing hardware-backed encryption. Auth tokens and refresh tokens stored here cannot be read even if someone extracts the device's data directory.

The alternative backends (Hive, SQLite, SharedPreferences) write plaintext or weakly-encrypted files to disk. Storing auth tokens in any of them would be a security vulnerability.

**What uses it:**
- `AuthLocalDataSources` — saves access token + refresh token after login
- `ProfileLocalDataSources` — deletes both tokens on logout

**Rule:** Only use `SecureDatabase` for secrets (tokens, keys, credentials). For everything else, use `AppStorage`.

### `AppStorage` — general feature local cache (variability point)

```
lib/core/storage/app_storage.dart
lib/core/storage/impl/<provider>.dart   ← one file per active provider
lib/core/storage/storage_module.dart    ← SPL-managed, do not edit manually
```

Used by features that need to cache data locally — product lists, user preferences, onboarding state, etc. Multiple backends can be active at once; each feature picks its own. No security guarantee is assumed.

Generated local data sources use `@Named` to inject the correct backend:
```dart
@LazySingleton(as: OrdersLocalDataSources)
class OrdersLocalDataSourcesImpl implements OrdersLocalDataSources {
  final AppStorage _storage;
  const OrdersLocalDataSourcesImpl(@Named('sqflite') this._storage);
}
```

Add a feature with local storage pre-wired:
```
dart run codegen/spl_manager.dart add orders --with-storage       # uses default backend
dart run codegen/spl_manager.dart add orders --storage sqflite    # specific backend
dart run codegen/spl_manager.dart add orders,storage=sqflite      # inline equivalent
```

---

## Feature Management

### Feature lifecycle

```
add → active ──disable──→ catalog ──enable──→ active
                              └──remove──→ gone forever
```

Features have three states:
- **Active** — code lives in `lib/features/<name>/`, compiled, DI-wired
- **Catalog** — code lives in `features_catalog/<name>/`, not compiled, not in DI, fully preserved
- **Removed** — hard deleted, gone

`features_catalog/` is excluded from Dart analysis so inactive features never cause compile errors.

### Adding a feature

Each argument to `add` is a **feature spec**: a feature name optionally followed by comma-separated inline options.

```
<name>[,storage=<provider>][,state=<solution>][,test][,shell]
```

Examples:
```
# Single feature, no options
dart run codegen/spl_manager.dart add orders

# Single feature with options inline
dart run codegen/spl_manager.dart add orders,storage=sqflite,state=cubit,test

# Multiple features, each with their own config
dart run codegen/spl_manager.dart add orders,storage=sqflite,state=cubit feed,test settings,shell

# Global flags apply to all features that don't override them inline
dart run codegen/spl_manager.dart add orders inventory,storage=hive settings --state bloc --with-test
# → orders:    bloc + test  (from global flags)
# → inventory: hive + test  (storage from inline, test from global)
# → settings:  bloc + test  (from global flags)
```

**Available inline keys:**

| Key | Equivalent flag | Description |
|---|---|---|
| `storage=<provider>` | `--storage <provider>` | Use a specific backend |
| `with-storage` or `ws` | `--with-storage` | Use the default backend |
| `state=<solution>` | `--state <solution>` | State management override |
| `test` | `--with-test` | Generate tests |
| `shell` | `--shell-route` | Register as shell (bottom nav) route |

**Global flags** (apply to all features unless overridden inline):

| Flag | Description |
|---|---|
| `--with-storage` | Use default storage backend for all |
| `--storage <provider>` | Use specific backend for all |
| `--state <solution>` | State management for all |
| `--with-test` | Generate tests for all |
| `--shell-route` | Shell route for all |

This scaffolds a full clean architecture feature:

```
lib/features/<name>/
  data/
    local/<name>_local_data_sources.dart        (only with storage option)
    model/
      mapper/<name>_mapper.dart
      responses/<name>_response.dart
    remote/<name>_remote_data_sources.dart
    <name>_repository_impl.dart
  domain/
    model/<name>.dart
    repository/<name>_repository.dart
    use_cases/<name>_use_cases.dart
    <name>_interactor.dart
  presentation/
    pages/<name>_page.dart
    blocs/                                      (bloc or cubit)
      <name>_event.dart                         (bloc only)
      <name>_state.dart
      <name>_bloc.dart | <name>_cubit.dart
    providers/                                  (riverpod only)
      <name>_state.dart
      <name>_notifier.dart

test/features/<name>/                           (only with test option)
  domain/<name>_interactor_test.dart
  presentation/<name>_bloc_test.dart | <name>_cubit_test.dart | <name>_notifier_test.dart
```

The route is injected automatically into `lib/core/router/app_router_config.dart`. Use `shell` (inline) or `--shell-route` (global) to register inside the `ShellRoute` (bottom nav); omit for a top-level route.

DI is auto-wired — `build_runner` regenerates `lib/services/di.config.dart` automatically. When adding multiple features, `build_runner` runs once at the end.

### Disabling a feature

```
dart run codegen/spl_manager.dart disable <name>
dart run codegen/spl_manager.dart disable orders inventory settings   # multiple at once
```

Moves `lib/features/<name>/` to `features_catalog/<name>/`, marks it `inactive` in `spl.yaml`, and regenerates DI. The code is fully preserved — nothing is deleted.

If other features import the disabled feature, a warning is printed listing the affected files. The disable proceeds — fix the broken imports afterwards.

### Re-enabling a feature

```
dart run codegen/spl_manager.dart enable <name>
dart run codegen/spl_manager.dart enable orders inventory            # multiple at once
```

Moves `features_catalog/<name>/` back to `lib/features/<name>/`, marks it `active` in `spl.yaml`, and re-wires DI. All original code is restored exactly as it was left.

### Hard deleting a feature

```
dart run codegen/spl_manager.dart remove <name>
dart run codegen/spl_manager.dart remove <name> --yes               # skip confirmation
dart run codegen/spl_manager.dart remove orders inventory --yes     # multiple at once
```

Permanently deletes the feature from wherever it lives (active or catalog), removes its route and tests, and removes it from `spl.yaml`. Irreversible.

If other features import the feature being removed, the CLI **blocks** and lists the dependent files. Pass `--yes` to force the deletion anyway (you will need to fix the broken imports manually).

---

## Template Features

The four features included in this template (`authentication`, `onboarding`, `product`, `profile`) are working demonstrations of the architecture. They use the DummyJson API and show real usage of the data/domain/presentation layers.

Keep them as reference — remove them when you no longer need the examples:

```
dart run codegen/spl_manager.dart remove authentication onboarding product profile --yes
```

---

## Mason Bricks

The CLI uses [Mason](https://pub.dev/packages/mason_cli) for code generation if available, otherwise falls back to inline templates.

Run once to initialize:
```
mason get
```

After that, `spl_manager add` uses Mason automatically. You can also invoke bricks directly:
```
mason make feature --name orders
```

Brick templates live in `bricks/`. They are excluded from Dart analysis (`analysis_options.yaml`) because they contain Mustache syntax (`{{name.pascalCase()}}`), not valid Dart.

---

## CLI Source Layout

The CLI is split across multiple files using Dart's `part`/`part of` directives. All parts share a single library — `codegen/spl_manager.dart` — so every private function is accessible everywhere with no extra imports.

```
codegen/
├── spl_manager.dart        entry point — library declaration, import 'dart:io', main(), part directives
└── src/
    ├── commands.dart        _cmdList, _cmdAdd, _cmdDisable, _cmdEnable, _cmdRemove, _cmdStorage*, _cmdState*, _cmdFix
    ├── generators.dart      _generateFeatureFiles, _stateFiles, _injectRoute, _removeRoute, _removeTests, _generateTestFiles, _checkCrossFeatureDeps
    ├── storage_manager.dart _getDefaultProviderName, _getActiveProviders, _ensureStorageActive, _rewriteStorageModule, _implFileName, _deleteStorageImpl, _generateStorageImpl
    ├── templates.dart       all _tpl* functions — state mgmt, storage providers, data/domain layer, tests
    ├── spl_config.dart      spl.yaml read/write helpers, Mason integration (_checkMason, _tryMason*)
    └── utils.dart           _parseFeatureSpec, _validateStateChoice, _printNotes, _runBuildRunner, _toPascalCase, _printHelp, _die
```

To extend the CLI — add a command, add a template — edit only the relevant part file.

---

## DI Regeneration

All generated code uses `@injectable` / `@lazySingleton` annotations. After any `add`, `disable`, `enable`, or `remove` command, `build_runner` is run automatically to regenerate `lib/services/di.config.dart`.

When operating on multiple features at once, `build_runner` runs **once** at the end rather than after each feature.

To run it manually:
```
dart run codegen/spl_manager.dart fix
```
