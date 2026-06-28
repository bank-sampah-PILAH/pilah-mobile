import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/constants/app_key.dart';

import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies(environment: AppKey.prodEnv);
  
  await di.get<AppStorage>(instanceName: 'shared_preferences').init();
  await di<NetworkUtils>().init();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Google Sign-In (required for v7+)
  await GoogleSignIn.instance.initialize();

  runApp(const App());
}
