import 'package:pilah_mobile/main_development.dart' as development;

/// Default entrypoint: `flutter run` and `flutter build` target this file
/// whenever no `-t` flag is passed.
///
/// It delegates to the development bootstrap rather than duplicating it, so the
/// two cannot drift apart. An unflagged run therefore starts the real app
/// against the dev environment — previously this file held the `flutter create`
/// placeholder, which meant an unflagged `flutter build apk --release` would
/// have shipped a "Hello World" screen.
///
/// Development is the default deliberately: an accidental run should never be
/// the one that reaches production data.
///
/// Production stays explicit:
///   flutter build apk --release -t lib/main_production.dart
Future<void> main() => development.main();
