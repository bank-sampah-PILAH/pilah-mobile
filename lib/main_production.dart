// coverage:ignore-file
// Process entrypoint: real dotenv, Firebase, Google Sign-In and runApp bootstrap; not
// runnable in a unit-test VM.
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/core/errors/error_handlers.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/utils/platform_initialization.dart';
import 'package:pilah_mobile/core/utils/firebase_initialization.dart';
import 'package:pilah_mobile/core/notifications/firebase_push.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_key.dart';

import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';

/// The whole of the app starts inside one zone, so an error thrown later by a
/// timer or a future nobody awaits is reported too: on the web it reaches
/// nothing else. Until the real reporter is built, errors are dropped.
Future<void> main() async {
  final reporter = LateErrorReporter(
    () => di.isRegistered<ErrorReporter>() ? di<ErrorReporter>() : null,
  );
  ErrorHandlers.runGuarded(reporter, () {
    ErrorHandlers.install(reporter);
    _start();
  });
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  configureDependencies(environment: AppKey.prodEnv);

  await di.get<AppStorage>(instanceName: 'shared_preferences').init();
  await di<NetworkUtils>().init();

  await initializePlatformServices(
    isWeb: kIsWeb,
    initializeFirebaseOnWeb: kIsWeb && firebaseWebConfigured(dotenv.env),
    oauthClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    initializeFirebase: () => initializeFirebaseForEnvironment(
      dotenv.env,
      isWeb: kIsWeb,
    ),
    initializeGoogle: GoogleSignIn.instance.initialize,
  );
  runApp(const App());
  requestNotificationPermissionAfterFirstFrame();
}
