import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_key.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies(environment: AppKey.prodEnv);
  runApp(const App());
}
