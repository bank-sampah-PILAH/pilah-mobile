# 👨‍💻 Flutter Boilerplate

[![Generic badge](https://img.shields.io/badge/Flutter-v3.41.3-blue)](https://flutter.dev/docs)[![Generic badge](https://img.shields.io/badge/Dart-v3.11.1-blue)](https://dart.dev/guides)

Flutter Template

## ⚡️ Getting Started

### 🚚 How to run, drive, and build Apk

Add .env file to the project directory (see .env.example)

Example how to run development app

```
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Example how to run production app

```
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk -t lib/main_production.dart
```

### ⚙️ Supported Flavor

1.  staging
2.  production

### 🎯 Architecture & Pattern

Reso coder's flutter clean architecture

![alt text](https://i0.wp.com/resocoder.com/wp-content/uploads/2019/08/Clean-Architecture-Flutter-Diagram.png?ssl=1)

### 🧬️ State Management

Since we use clean architecture, it doesn't matter what state management you prefer to use

But for this project example, we use [Bloc](https://pub.dev/packages/flutter_bloc)

### 🧩 Software Product Line (SPL)

This template includes an SPL layer for managing variability — swappable storage backends and state management solutions, plus a CLI to add/remove/toggle features.

See [SPL.md](SPL.md) for the full guide.

```
dart run codegen/spl_manager.dart list
dart run codegen/spl_manager.dart add <feature>
dart run codegen/spl_manager.dart disable <feature>
dart run codegen/spl_manager.dart enable <feature>
dart run codegen/spl_manager.dart storage set hive
dart run codegen/spl_manager.dart state set cubit
```

### 🧱 Mason (Code Generation)

This project uses [Mason](https://pub.dev/packages/mason_cli) for brick-based code generation. Bricks are stored in `bricks/` as real `.dart` files with Mustache variables.

Install Mason globally (one-time):

```
dart pub global activate mason_cli
```

Initialize bricks for this project (one-time, after `flutter pub get`):

```
mason get
```

The SPL CLI (`spl_manager.dart`) uses Mason automatically when available. You can also invoke bricks directly:

```
mason make feature --name <name>mason make feature --name <name> --with_storage true --state cubit
```

Bricks are excluded from Dart analysis (`analysis_options.yaml`) because they contain Mustache syntax (`{{name.pascalCase()}}`), not valid Dart.

### API Documentation

[DummyJson](https://dummyjson.com/docs/)

This boilerplate use DummyJson for remote data sources

See [Auth](https://dummyjson.com/docs/auth) to obtain username and password to login in this app

### :capital_abcd: Naming Convention

snake_case for file and folder.

### :capital_abcd: Git flow

Commit rules:(feat|fix|docs|style|refactor|perf|test|build|ci):/\*

feat: A new feature

fix: A bug fix

docs: Documentation only changes

style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)

refactor: A code change that neither fixes a bug nor adds a feature

perf: A code change that improves performance

test: Adding missing tests

build: Changes to the build/compilation/packaging process or auxiliary tools such as documentation generation

ci: Changes in the continuous integration/delivery setup

#### examples:

feat(auth): Form Login

feat(product): implement product screen

ci: refactor analysis job

#### before push

1.  flutter analyze
2.  flutter test

branch rules:(feature|hotfix|coldfix|service|integration|ui)//\*

### How to contribute

To help work on this project, please refer to [CONTRIBUTING.md](CONTRIBUTING.md)
