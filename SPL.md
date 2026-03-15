# Software Product Line (SPL) Guide

This project uses Software Product Line Engineering (SPLE) to manage variability points — features and behaviors that can differ between products derived from this template.

All variability is managed through a single CLI tool and a single config file.

---

## Quick Reference

```
dart run codegen/spl_manager.dart list
dart run codegen/spl_manager.dart add <name> [--with-storage] [--state bloc|cubit|riverpod]
dart run codegen/spl_manager.dart disable <name>             # deactivate, keep code
dart run codegen/spl_manager.dart enable <name>              # restore from catalog
dart run codegen/spl_manager.dart remove <name> [--yes|-y]  # hard delete
dart run codegen/spl_manager.dart storage set <provider>
dart run codegen/spl_manager.dart storage list
dart run codegen/spl_manager.dart state set <bloc|cubit|riverpod>
dart run codegen/spl_manager.dart state list
dart run codegen/spl_manager.dart fix
```

---

## Source of Truth: `spl.yaml`

`spl.yaml` is the single source of truth for the product configuration. It tracks the active storage backend, the default state management solution, and all features.

Do not edit `spl.yaml` by hand — use the CLI. The CLI updates this file, generates/deletes code, and re-wires DI automatically.

---

## Variability Points

This project has two variability points. They have different exclusivity rules.

### 1. Storage — XOR (exactly one active)

Controls the backend for `AppStorage`, the general-purpose local caching interface used by features that need to persist data locally (e.g., cached lists, user preferences).

| Provider | Notes |
|---|---|
| `flutter_secure_storage` | Default. Encrypted key-value. No `init()` needed. |
| `hive` | Fast binary key-value. Requires `hive_flutter` in `pubspec.yaml` and `AppStorage.init()` before `runApp()`. |
| `sqflite` | SQLite. Requires `AppStorage.init()` before `runApp()`. |
| `shared_preferences` | Simple unencrypted key-value. Requires `shared_preferences` in `pubspec.yaml` and `AppStorage.init()` before `runApp()`. |

**XOR means**: switching providers deletes the old implementation file and generates the new one. Only the active provider's impl file exists in `lib/core/storage/impl/`.

```
dart run codegen/spl_manager.dart storage set hive
```

This regenerates `lib/core/storage/impl/hive_storage_provider.dart`, rewrites `lib/core/storage/storage_module.dart` to wire the new impl, and runs `build_runner`.

### 2. State Management — OR (global default + per-feature override)

Controls the presentation layer pattern for features. Unlike storage, this is **not exclusive** — different features in the same app can use different state management solutions.

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
lib/core/storage/impl/<active_provider>.dart   ← only one file exists at a time
lib/core/storage/storage_module.dart           ← SPL-managed, do not edit manually
```

Used by features that need to cache data locally — product lists, user preferences, onboarding state, etc. The backend is switchable via `storage set`. No security guarantee is assumed.

Inject it in your local data source:
```dart
@LazySingleton(as: MyLocalDataSources)
class MyLocalDataSourcesImpl implements MyLocalDataSources {
  final AppStorage _storage;
  MyLocalDataSourcesImpl(this._storage);
}
```

Add a feature with local storage pre-wired:
```
dart run codegen/spl_manager.dart add orders --with-storage
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

```
dart run codegen/spl_manager.dart add <name>
dart run codegen/spl_manager.dart add <name> --with-storage
dart run codegen/spl_manager.dart add <name> --state cubit
dart run codegen/spl_manager.dart add <name> --with-storage --state riverpod
```

This scaffolds a full clean architecture feature:

```
lib/features/<name>/
  data/
    local/<name>_local_data_sources.dart        (only with --with-storage)
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
```

After scaffolding, register the route manually in `lib/core/router/app_router_config.dart`.

DI is auto-wired — `build_runner` regenerates `lib/services/di.config.dart` automatically.

### Disabling a feature

```
dart run codegen/spl_manager.dart disable <name>
```

Moves `lib/features/<name>/` to `features_catalog/<name>/`, marks it `inactive` in `spl.yaml`, and regenerates DI. The code is fully preserved — nothing is deleted.

### Re-enabling a feature

```
dart run codegen/spl_manager.dart enable <name>
```

Moves `features_catalog/<name>/` back to `lib/features/<name>/`, marks it `active` in `spl.yaml`, and re-wires DI. All original code is restored exactly as it was left.

### Hard deleting a feature

```
dart run codegen/spl_manager.dart remove <name>
dart run codegen/spl_manager.dart remove <name> --yes
```

Permanently deletes the feature from wherever it lives (active or catalog) and removes it from `spl.yaml`. Irreversible. Add `--yes` (or `-y`) to skip the confirmation prompt.

---

## Template Features

The four features included in this template (`authentication`, `onboarding`, `product`, `profile`) are working demonstrations of the architecture. They use the DummyJson API and show real usage of the data/domain/presentation layers.

Keep them as reference — remove them when you no longer need the examples:

```
dart run codegen/spl_manager.dart remove authentication --yes
dart run codegen/spl_manager.dart remove onboarding --yes
dart run codegen/spl_manager.dart remove product --yes
dart run codegen/spl_manager.dart remove profile --yes
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

## DI Regeneration

All generated code uses `@injectable` / `@lazySingleton` annotations. After any `add` or `remove` command, `build_runner` is run automatically to regenerate `lib/services/di.config.dart`.

To run it manually:
```
dart run codegen/spl_manager.dart fix
```
