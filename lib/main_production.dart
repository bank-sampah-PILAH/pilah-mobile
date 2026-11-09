// coverage:ignore-file
// Process entrypoint: real dotenv, Firebase, Google Sign-In and runApp bootstrap; not
// runnable in a unit-test VM.
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/utils/platform_initialization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_key.dart';

import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  configureDependencies(environment: AppKey.prodEnv);

  await di.get<AppStorage>(instanceName: 'shared_preferences').init();
  await di<NetworkUtils>().init();

  await initializePlatformServices(
    isWeb: kIsWeb,
    initializeFirebaseOnWeb:
        kIsWeb && (dotenv.env['FIREBASE_WEB_APP_ID']?.isNotEmpty ?? false),
    oauthClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    initializeFirebase: () async {
      await Firebase.initializeApp(
        options: kIsWeb
            ? FirebaseOptions(
                apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? '',
                appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '',
                messagingSenderId:
                    dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
                projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
              )
            : null,
      );
    },
    initializeGoogle: GoogleSignIn.instance.initialize,
  );
  runApp(const App());
}
