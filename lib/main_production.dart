// coverage:ignore-file
// Process entrypoint: real dotenv, Firebase, Google Sign-In and runApp bootstrap; not
// runnable in a unit-test VM.
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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

  // ponytail: Web has no Firebase-backed features yet; add FlutterFire options
  // before one is introduced.
  if (!kIsWeb) await Firebase.initializeApp();

  // Initialize Google Sign-In (required for v7+)
  final googleClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb ? googleClientId : null,
    serverClientId: kIsWeb ? null : googleClientId,
  );

  runApp(const App());
}
